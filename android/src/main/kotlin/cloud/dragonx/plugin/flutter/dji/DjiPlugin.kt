package cloud.dragonx.plugin.flutter.dji

import android.Manifest
import android.util.Log
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerialName
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import dji.common.error.DJIError
import dji.common.flightcontroller.LocationCoordinate3D
import dji.common.gimbal.Attitude
import dji.common.gimbal.Rotation
import dji.common.mission.hotpoint.HotpointHeading
import dji.common.mission.hotpoint.HotpointMission
import dji.common.mission.hotpoint.HotpointStartPoint
import dji.common.mission.waypoint.Waypoint
import dji.common.mission.waypoint.WaypointAction
import dji.common.mission.waypoint.WaypointActionType
import dji.common.mission.waypoint.WaypointMission
import dji.common.mission.waypoint.WaypointMissionFinishedAction
import dji.common.mission.waypoint.WaypointMissionFlightPathMode
import dji.common.mission.waypoint.WaypointMissionGotoWaypointMode
import dji.common.mission.waypoint.WaypointMissionHeadingMode
import dji.common.model.LocationCoordinate2D
import dji.common.util.CommonCallbacks
import dji.sdk.base.BaseProduct
import dji.sdk.flightcontroller.FlightController
import dji.sdk.mission.MissionControl
import dji.sdk.mission.Triggerable
import dji.sdk.mission.timeline.TimelineElement
import dji.sdk.mission.timeline.TimelineEvent
import dji.sdk.mission.timeline.TimelineMission
import dji.sdk.mission.timeline.actions.GimbalAttitudeAction
import dji.sdk.mission.timeline.actions.GoHomeAction
import dji.sdk.mission.timeline.actions.GoToAction
import dji.sdk.mission.timeline.actions.HotpointAction
import dji.sdk.mission.timeline.actions.RecordVideoAction
import dji.sdk.mission.timeline.actions.ShootPhotoAction
import dji.sdk.mission.timeline.actions.TakeOffAction
import dji.sdk.mission.timeline.triggers.AircraftLandedTrigger
import dji.sdk.mission.timeline.triggers.BatteryPowerLevelTrigger
import dji.sdk.mission.timeline.triggers.Trigger
import dji.sdk.mission.timeline.triggers.TriggerEvent
import dji.sdk.mission.timeline.triggers.WaypointReachedTrigger
import dji.sdk.products.Aircraft
import dji.sdk.sdkmanager.DJISDKInitEvent

import dji.sdk.base.BaseComponent

import dji.sdk.sdkmanager.DJISDKManager

import dji.common.error.DJISDKError

import dji.log.DJILog
import dji.sdk.base.BaseProduct.ComponentKey
import dji.sdk.sdkmanager.DJISDKManager.SDKManagerCallback


/** DjiPlugin */

class DjiPlugin: FlutterPlugin, Messages.DjiHostApi {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  var fltDjiFlutterApi: Messages.DjiFlutterApi? = null
  val fltDrone = Messages.Drone()

  var drone: Aircraft? = null
  var droneCurrentLocation: LocationCoordinate3D? = null

  var flight: Flight? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    Messages.DjiHostApi.setup(flutterPluginBinding.binaryMessenger, this)
    fltDjiFlutterApi = Messages.DjiFlutterApi(flutterPluginBinding.binaryMessenger)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Messages.DjiHostApi.setup(binding.binaryMessenger, null)
  }

  private fun _fltSetStatus(status: String) {
    fltDrone.status = status

    fltDjiFlutterApi?.setStatus(fltDrone) {
      print("=== Android: setStatus Closure Success: $status")
    }
  }

  override fun getPlatformVersion(): Messages.Version {
    var result = Messages.Version()
    result.string = "Android ${android.os.Build.VERSION.RELEASE}"
    return result
  }

  override fun getBatteryLevel(): Messages.Battery {
    TODO("Not yet implemented")
  }

  companion object {
    private val TAG = "=== DjiPlugin Android"
//    const val FLAG_CONNECTION_CHANGE = "dji_sdk_connection_change"
    private val mProduct: BaseProduct? = null
//    private val REQUIRED_PERMISSION_LIST = arrayOf<String>(
//      Manifest.permission.VIBRATE,
//      Manifest.permission.INTERNET,
//      Manifest.permission.ACCESS_WIFI_STATE,
//      Manifest.permission.WAKE_LOCK,
//      Manifest.permission.ACCESS_COARSE_LOCATION,
//      Manifest.permission.ACCESS_NETWORK_STATE,
//      Manifest.permission.ACCESS_FINE_LOCATION,
//      Manifest.permission.CHANGE_WIFI_STATE,
//      Manifest.permission.WRITE_EXTERNAL_STORAGE,
//      Manifest.permission.BLUETOOTH,
//      Manifest.permission.BLUETOOTH_ADMIN,
//      Manifest.permission.READ_EXTERNAL_STORAGE,
//      Manifest.permission.READ_PHONE_STATE
//    )
//    private const val REQUEST_PERMISSION_CODE = 12345
  }

  override fun registerApp() {
    DJISDKManager.getInstance().registerApp(null, object : SDKManagerCallback {
      override fun onRegister(djiError: DJIError) {
        if (djiError === DJISDKError.REGISTRATION_SUCCESS) {
//          DJILog.e("App registration", DJISDKError.REGISTRATION_SUCCESS.description)
          Log.v(TAG, "Register Success")
          _fltSetStatus("Registered")
        } else {
          Log.v(TAG, "Register Failed")
          Log.v(TAG, djiError.description)
        }
      }

      override fun onProductConnect(baseProduct: BaseProduct) {
        Log.d(TAG, String.format("Product Connected: %s", baseProduct))
        _fltSetStatus("Connected")
      }

      override fun onProductDisconnect() {
        Log.d(TAG, "Product Disconnected")
        _fltSetStatus("Disconnected")
      }

      override fun onProductChanged(baseProduct: BaseProduct) {}

      override fun onComponentChange(
        componentKey: ComponentKey, oldComponent: BaseComponent,
        newComponent: BaseComponent
      ) {
        if (newComponent != null) {
          newComponent.setComponentListener { isConnected ->
            Log.d(TAG,"onComponentConnectivityChanged: $isConnected")
          }
        }
        Log.d(
          TAG, String.format(
            "onComponentChange key: %s, oldComponent: %s, newComponent: %s",
            componentKey,
            oldComponent,
            newComponent
          )
        )
      }

      override fun onInitProcess(djisdkInitEvent: DJISDKInitEvent, i: Int) {}
      override fun onDatabaseDownloadProgress(l: Long, l1: Long) {}
    })
  }

  override fun connectDrone() {
    Log.d(TAG, "Connect Drone Started")
    DJISDKManager.getInstance().startConnectionToProduct()
  }

  override fun disconnectDrone() {
    Log.d(TAG, "Disconnect Drone Started")
    DJISDKManager.getInstance().stopConnectionToProduct()
  }

  override fun delegateDrone() {
    TODO("Not yet implemented")
  }

  override fun takeOff() {
    TODO("Not yet implemented")
  }

  override fun land() {
    TODO("Not yet implemented")
  }

  override fun timeline() {
    TODO("Not yet implemented")
  }

  override fun start(flightJson: String?) {
    TODO("Not yet implemented")
  }
}

/** Flight Classes */

@Serializable
data class Flight(
  @SerialName("timeline")
  val timeline: List<FlightElement>?
)

@Serializable
data class FlightElement(
  @SerialName("type")
  val type: String?,
  @SerialName("pointOfInterest")
  val pointOfInterest: FlightLocation?,
  @SerialName("maxFlightSpeed")
  val maxFlightSpeed: Double?,
  @SerialName("autoFlightSpeed")
  val autoFlightSpeed: Double?,
  @SerialName("finishedAction")
  val finishedAction: String?,
  @SerialName("headingMode")
  val headingMode: String?,
  @SerialName("flightPathMode")
  val flightPathMode: String?,
  @SerialName("rotateGimbalPitch")
  val rotateGimbalPitch: Boolean?,
  @SerialName("exitMissionOnRCSignalLost")
  val exitMissionOnRCSignalLost: Boolean?,
  @SerialName("waypoints")
  val waypoints: List<FlightWaypoint>?
)

@Serializable
data class FlightWaypoint(
  @SerialName("location")
  val location: FlightLocation?,
  @SerialName("heading")
  val heading: Int?,
  @SerialName("cornerRadiusInMeters")
  val cornerRadiusInMeters: Double?,
  @SerialName("turnMode")
  val turnMode: String?,
  @SerialName("gimbalPitch")
  val gimbalPitch: Double?
)

@Serializable
data class FlightLocation(
  @SerialName("altitude")
  val altitude: Double?,
  @SerialName("latitude")
  val latitude: Double?,
  @SerialName("longitude")
  val longitude: Double?
)

@Serializable
data class Vector(
  @SerialName("destinationAltitude")
  val destinationAltitude: Int?,
  @SerialName("distanceFromPointOfInterest")
  val distanceFromPointOfInterest: Int?,
  @SerialName("headingRelativeToPointOfInterest")
  val headingRelativeToPointOfInterest: Int?
)

//import androidx.annotation.NonNull
//
//import io.flutter.embedding.engine.plugins.FlutterPlugin
//import io.flutter.plugin.common.MethodCall
//import io.flutter.plugin.common.MethodChannel
//import io.flutter.plugin.common.MethodChannel.MethodCallHandler
//import io.flutter.plugin.common.MethodChannel.Result
//
///** DjiPlugin */
//class DjiPlugin: FlutterPlugin, MethodCallHandler {
//  /// The MethodChannel that will the communication between Flutter and native Android
//  ///
//  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
//  /// when the Flutter Engine is detached from the Activity
//  private lateinit var channel : MethodChannel
//
//  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
//    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dji")
//    channel.setMethodCallHandler(this)
//  }
//
//  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
//    if (call.method == "getPlatformVersion") {
//      result.success("Android ${android.os.Build.VERSION.RELEASE}")
//    } else {
//      result.notImplemented()
//    }
//
//    if (call.method == "getPlatformVersion") {
//      result.success("Android ${android.os.Build.VERSION.RELEASE}")
//    } else {
//      result.notImplemented()
//    }
//  }
//
//  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
//    channel.setMethodCallHandler(null)
//  }
//}
