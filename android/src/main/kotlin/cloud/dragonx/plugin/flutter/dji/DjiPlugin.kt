package cloud.dragonx.plugin.flutter.dji

import android.Manifest
import android.R.attr
import android.app.Activity
import android.app.PendingIntent.getActivity
import android.content.Context
import android.app.Application
import android.content.res.AssetManager
import android.util.AttributeSet
import android.util.Log
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerialName
import androidx.annotation.NonNull
import androidx.appcompat.app.AppCompatActivity
import com.secneo.sdk.Helper

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
import dji.common.model.LocationCoordinate2D
import dji.common.util.CommonCallbacks
import dji.sdk.base.BaseProduct
import dji.sdk.flightcontroller.FlightController
import dji.sdk.mission.MissionControl
import dji.sdk.mission.Triggerable
import dji.sdk.mission.timeline.TimelineElement
import dji.sdk.mission.timeline.TimelineEvent
import dji.sdk.mission.timeline.TimelineMission
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
//import dji.midware.util.ContextUtil.getContext
import dji.sdk.base.BaseProduct.ComponentKey
import dji.sdk.sdkmanager.DJISDKManager.SDKManagerCallback
import dji.thirdparty.afinal.core.AsyncTask
import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.coroutineContext

import androidx.multidex.MultiDex
import dji.common.battery.BatteryState
import dji.common.mission.waypoint.*
import dji.midware.data.model.P3.DataCameraInfoNotify
import dji.sdk.mission.timeline.actions.*
import dji.waypointv2.common.waypointv1.TurnMode
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import java.lang.Exception
import java.util.*
import android.os.Environment

import java.io.File
import dji.sdk.camera.PlaybackManager
import dji.sdk.camera.PlaybackManager.FileDownloadCallback


/** DjiPlugin */

class DjiPlugin: FlutterPlugin, Messages.DjiHostApi, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  // How to get context and activity in Flutter Plugin for android:
  // https://www.jianshu.com/p/eb7df49fdfb1
  private lateinit var djiPluginActivity:Activity
  private lateinit var djiPluginContext: Context

  var fltDjiFlutterApi: Messages.DjiFlutterApi? = null
  val fltDrone = Messages.Drone()

  var drone: Aircraft? = null
  var droneCurrentLocation: LocationCoordinate3D? = null // Note: this is different from DJI SDK iOS where CLLocation.coordinate is used (LocationCoordinate3D in dji-android is the same as CLLocation.coordinate in dji-ios).

  var flight: Flight? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    Messages.DjiHostApi.setup(flutterPluginBinding.binaryMessenger, this)
    fltDjiFlutterApi = Messages.DjiFlutterApi(flutterPluginBinding.binaryMessenger)

    this.djiPluginContext = flutterPluginBinding.applicationContext
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    Messages.DjiHostApi.setup(binding.binaryMessenger, null)

    val _missionControl = MissionControl.getInstance()
    if (_missionControl != null && _missionControl.scheduledCount() > 0) {
      _missionControl.unscheduleEverything()
      _missionControl.removeAllListeners()
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.djiPluginActivity = binding.activity

    // [ ! ] DJI SDK Must be "installed" using this function, before any method of DJI SDK is used.
    MultiDex.install(this.djiPluginContext)
    Helper.install(this.djiPluginActivity.application)
  }
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }
  override fun onDetachedFromActivityForConfigChanges() {}
  override fun onDetachedFromActivity() {}

  /* ## */

  private fun _fltSetStatus(status: String) {
    fltDrone.status = status

    djiPluginActivity.runOnUiThread(Runnable {
      fltDjiFlutterApi?.setStatus(fltDrone) {
        Log.d(TAG, "setStatus Closure Success: $status")
      }
    })
  }

  override fun getPlatformVersion(): Messages.Version {
    val result = Messages.Version()
    result.string = "Android ${android.os.Build.VERSION.RELEASE}"
    return result
  }

  override fun getBatteryLevel(): Messages.Battery {
    TODO("Not yet implemented")
  }

  companion object {
    private val TAG = "=== DjiPlugin Android"
    const val FLAG_CONNECTION_CHANGE = "dji_sdk_connection_change"
    private val mProduct: BaseProduct? = null
    private val REQUIRED_PERMISSION_LIST = arrayOf<String>(
      Manifest.permission.VIBRATE,
      Manifest.permission.INTERNET,
      Manifest.permission.ACCESS_WIFI_STATE,
      Manifest.permission.WAKE_LOCK,
      Manifest.permission.ACCESS_COARSE_LOCATION,
      Manifest.permission.ACCESS_NETWORK_STATE,
      Manifest.permission.ACCESS_FINE_LOCATION,
      Manifest.permission.CHANGE_WIFI_STATE,
      Manifest.permission.WRITE_EXTERNAL_STORAGE,
      Manifest.permission.BLUETOOTH,
      Manifest.permission.BLUETOOTH_ADMIN,
      Manifest.permission.READ_EXTERNAL_STORAGE,
      Manifest.permission.READ_PHONE_STATE
    )
    private const val REQUEST_PERMISSION_CODE = 12345
//    private val isRegistrationInProgress: AtomicBoolean = AtomicBoolean(false)
  }

  override fun registerApp() {
    Log.d(TAG, "Register App Started")
    DJISDKManager.getInstance().registerApp(djiPluginContext, object: SDKManagerCallback {
      override fun onRegister(djiError: DJIError) {
        if (djiError === DJISDKError.REGISTRATION_SUCCESS) {
          //DJILog.e("App registration", DJISDKError.REGISTRATION_SUCCESS.description)
          Log.d(TAG, "Register Success")
          _fltSetStatus("Registered")
        } else {
          Log.d(TAG, "Register Failed")
          Log.d(TAG, djiError.description)
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
        componentKey: ComponentKey, oldComponent: BaseComponent?,
        newComponent: BaseComponent?
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
    Log.d(TAG, "Delegate Drone Started")
    val product = DJISDKManager.getInstance().product
    if (product != null) {
      drone = (DJISDKManager.getInstance().product) as Aircraft?

      if (drone != null && (drone is Aircraft)) {
        if ((drone as Aircraft).flightController != null) {
          Log.d(TAG, "Drone Flight Controller successfully configured")

          // Configuring the Flight Controller State Callbacks
          (drone as Aircraft).flightController.setStateCallback { state ->
            var _droneLatitude: Double = 0.00
            var _droneLongitude: Double = 0.00
            var _droneAltitude: Double = 0.00
            var _droneSpeed: Double = 0.00
            var _droneRoll: Double = 0.00
            var _dronePitch: Double = 0.00
            var _droneYaw: Double = 0.00

            val altitude = state.aircraftLocation?.altitude
            if (altitude != null) {
              _droneAltitude = altitude.toDouble()
            }

            // Updating the drone's current location coordinates variable
            val droneLocation = state.aircraftLocation
            if (droneLocation != null) {
              droneCurrentLocation = droneLocation
            }

            val latitude = state.aircraftLocation?.latitude
            if (latitude != null) {
              _droneLatitude = latitude
            }

            val longitude = state.aircraftLocation?.longitude
            if (longitude != null) {
              _droneLongitude = longitude
            }

            val speed = Math.sqrt(Math.pow(state.velocityX.toDouble(), 2.00) + Math.pow(state.velocityX.toDouble(), 2.00))
            _droneSpeed = speed

            _droneRoll = state.attitude.roll
            _dronePitch = state.attitude.pitch
            _droneYaw = state.attitude.yaw

            // Confirm Landing
            if (state.isLandingConfirmationNeeded) {
              (drone as Aircraft).flightController.confirmLanding(null)
            }

            // Updating Flutter
            fltDrone.latitude = _droneLatitude
            fltDrone.longitude = _droneLongitude
            fltDrone.altitude = _droneAltitude
            fltDrone.speed = _droneSpeed
            fltDrone.roll = _droneRoll
            fltDrone.pitch = _dronePitch
            fltDrone.yaw = _droneYaw

            djiPluginActivity.runOnUiThread(Runnable {
              fltDjiFlutterApi?.setStatus(fltDrone) {
//                Log.d(TAG, "setStatus Closure Success")
              }
            })
          }
        } else {
          Log.d(TAG, "Drone Flight Controller Object does not exist")
          _fltSetStatus("Error")
          return
        }

        try {
          (drone as Aircraft).getBattery()
            .setStateCallback(BatteryState.Callback { djiBatteryState ->
              // Updating Flutter
              fltDrone.batteryPercent = djiBatteryState.chargeRemainingInPercent.toDouble()

              djiPluginActivity.runOnUiThread(Runnable {
                fltDjiFlutterApi?.setStatus(fltDrone) {}
              })

              //Log.d(TAG, "Drone Battery Delegate successfuly configured")
            })
        } catch (ignored: Exception) {
          Log.d(TAG, "Drone Battery Delegate Error - No Battery Object")
          _fltSetStatus("Error")
        }

        Log.d(TAG, "Delegations completed")
        _fltSetStatus("Delegated")
      } else {
        Log.d(TAG,"Error - Delegations - DJI Aircraft Object does not exist")
      }
    } else {
      Log.d(TAG, "Error - Delegations - DJI Product Object does not exist")
    }
  }

  override fun takeOff() {
    Log.d(TAG, "Takeoff Started")
    if ((drone as Aircraft).flightController != null) {
      Log.d(TAG,"Takeoff Started")
      (drone as Aircraft).flightController.startTakeoff(null)
    } else {
      Log.d(TAG,"Takeoff Failed - No Flight Controller")
    }
  }

  override fun land() {
    Log.d(TAG, "Land Started")
    if ((drone as Aircraft).flightController != null) {
      Log.d(TAG,"Landing Started")
      (drone as Aircraft).flightController.startLanding(null)
    } else {
      Log.d(TAG,"Landing Failed - No Flight Controller")
    }
  }

//  override fun timeline() {
//    Log.d(TAG, "Timeline Started")
//    val _droneFlightController : FlightController? = (drone as Aircraft).flightController
//    if (_droneFlightController != null) {
//      // First we check if a timeline is already running
//      val _missionControl = MissionControl.getInstance()
//      if (_missionControl.isTimelineRunning == true) {
//        Log.d(TAG, "Error - Timeline already running")
//        return
//      }
//
//      var droneCoordinates = droneCurrentLocation
//      if (droneCoordinates == null) {
//        Log.d(TAG, "Timeline Failed - No droneCurrentLocationCoordinates")
//        return
//      }
//
//      // Set Home Coordinates
//      val droneHomeLocation = LocationCoordinate2D(droneCoordinates.latitude, droneCoordinates.longitude)
//      _droneFlightController.setHomeLocation(droneHomeLocation, null)
//
//      val scheduledElements: MutableList<TimelineElement> = ArrayList<TimelineElement>()
//      val oneMeterOffset: Double = 0.00000899322
//
//      // Take Off
//      scheduledElements.add(TakeOffAction())
//
//      // Waypoint Mission
//      val waypointMissionBuilder = WaypointMission.Builder().autoFlightSpeed(5f)
//        .maxFlightSpeed(15f)
//        .setExitMissionOnRCSignalLostEnabled(true)
//        .finishedAction(WaypointMissionFinishedAction.NO_ACTION)
//        .flightPathMode(WaypointMissionFlightPathMode.CURVED)
//        .gotoFirstWaypointMode(WaypointMissionGotoWaypointMode.POINT_TO_POINT)
//        .headingMode(WaypointMissionHeadingMode.AUTO)
//        .repeatTimes(1)
//
//      val waypoints: MutableList<Waypoint> = LinkedList()
//
//      val firstPoint = Waypoint(droneHomeLocation.latitude + 10 * oneMeterOffset, droneHomeLocation.longitude, 2f)
//      val secondPoint = Waypoint(droneHomeLocation.latitude, droneHomeLocation.longitude + 10 * oneMeterOffset, 5f)
//
//      waypoints.add(firstPoint)
//      waypoints.add(secondPoint)
//
//      waypointMissionBuilder.waypointList(waypoints).waypointCount(waypoints.size)
//
//      val waypointMission = TimelineMission.elementFromWaypointMission(waypointMissionBuilder.build())
//      scheduledElements.add(waypointMission)
//
//      if (_missionControl.scheduledCount() > 0) {
//        _missionControl.unscheduleEverything()
//        _missionControl.removeAllListeners()
//      }
//
//      _missionControl.scheduleElements(scheduledElements)
//      _missionControl.startTimeline()
//    }
//  }

  override fun start(flightJson: String) {
    Log.d(TAG, "Start Flight JSON: $flightJson")

    if (flightJson != null) {
      try {
        val json = Json {
          ignoreUnknownKeys = true
        }
        val f: Flight = json.decodeFromString<Flight>(flightJson)
        Log.d(TAG, "Start Flight JSON parsed successfully: $f")

        startFlightTimeline(f)
      } catch (e: Error) {
        Log.d(TAG, "Error - Failed to parse Flight JSON: ${e.message}")
      }
    }
  }

  private fun startFlightTimeline(flight: Flight) {
    val timeline = flight.timeline
    if (timeline == null || timeline.isEmpty()) {
      Log.d(TAG, "startFlightTimeline - timeline List is empty")
      return
    }

    val _droneFlightController : FlightController? = (drone as Aircraft).flightController
    if (_droneFlightController == null) {
      Log.d(TAG, "startFlightTimeline - No Flight Controller")
      return
    }

    val scheduledElements: MutableList<TimelineElement> = ArrayList<TimelineElement>()

    for (flightElement in flight.timeline) {
      when (flightElement.type) {
        "takeOff" -> {
          // Take Off
          scheduledElements.add(TakeOffAction())
        }

        "land" -> {
          // Land
          scheduledElements.add(LandAction())
        }

        "waypointMission" -> {
          // Waypoint Mission
          val wayPointMission = waypointMission(flightElement)
          if (wayPointMission != null) {
            val waypointMissionAsTimelineElement = TimelineMission.elementFromWaypointMission(wayPointMission)
            scheduledElements.add(waypointMissionAsTimelineElement)
          }
        }

        "hotpointAction" -> {
          TODO("Hotpoint Action to be implemented...")
        }

        "singleShootPhoto" -> {
          scheduledElements.add(ShootPhotoAction.newShootSinglePhotoAction())
        }

        "startRecordVideo" -> {
          scheduledElements.add(RecordVideoAction.newStartRecordVideoAction())
        }

        "stopRecordVideo" -> {
          scheduledElements.add(RecordVideoAction.newStopRecordVideoAction())
        }
      }
    }

    val _missionControl = MissionControl.getInstance()
    if (_missionControl != null) {
        // Cleaning any previous scheduled elements
        if (_missionControl.scheduledCount() > 0) {
          _missionControl.unscheduleEverything()
          _missionControl.removeAllListeners()
        }

        // Adding the scheduled elements
        _missionControl.scheduleElements(scheduledElements)

        // Adding a listener to monitor the timeline and output errors
        _missionControl.addListener(MissionControl.Listener {
            element, event, error ->
              if (element != null) {
                if (element is TimelineMission) {
                  Log.d(TAG, (element as TimelineMission).missionObject.javaClass.simpleName + " event is " + event.toString() + " " + if (error == null) "" else error.description)
                } else {
                  Log.d(TAG, element.javaClass.simpleName + " event is " + event.toString() + " " + if (error == null) "" else error.description)
                }
              } else {
                Log.d(TAG, "Timeline Event is $event " + if (error == null) "" else "Failed:" + error.description)
              }
        })

        // Starting the Timeline Mission
        _missionControl.startTimeline()
    } else {
      Log.d(TAG, "startFlightTimeline - No Mission Control or Scheduled Elements")
      return
    }
  }

  /** DJI Timeline Methods */
  private fun waypointMission(flightElementWaypointMission: FlightElement): WaypointMission? {

    var _maxFlightSpeed: Float = 15.toFloat()
    if (flightElementWaypointMission.maxFlightSpeed != null) {
      _maxFlightSpeed = flightElementWaypointMission.maxFlightSpeed.toFloat()
    }

    var _autoFlightSpeed: Float = 8.toFloat()
    if (flightElementWaypointMission.autoFlightSpeed != null) {
      _autoFlightSpeed = flightElementWaypointMission.autoFlightSpeed.toFloat()
    }

    val _finishedAction: WaypointMissionFinishedAction = when (flightElementWaypointMission.finishedAction) {
      "autoLand" -> WaypointMissionFinishedAction.AUTO_LAND
      "continueUntilStop" -> WaypointMissionFinishedAction.CONTINUE_UNTIL_END
      else -> WaypointMissionFinishedAction.NO_ACTION
    }

    val _headingMode: WaypointMissionHeadingMode = when (flightElementWaypointMission.headingMode) {
      "auto" -> WaypointMissionHeadingMode.AUTO
      "towardPointOfInterest" -> WaypointMissionHeadingMode.TOWARD_POINT_OF_INTEREST
      else -> WaypointMissionHeadingMode.USING_WAYPOINT_HEADING
    }

    val _flightPathMode: WaypointMissionFlightPathMode = when (flightElementWaypointMission.flightPathMode) {
      "normal" -> WaypointMissionFlightPathMode.NORMAL
      else -> WaypointMissionFlightPathMode.CURVED
    }

    var _rotateGimbalPitch: Boolean = true
    if (flightElementWaypointMission.rotateGimbalPitch != null) {
      _rotateGimbalPitch = flightElementWaypointMission.rotateGimbalPitch
    }

    var _exitMissionOnRCSignalLost: Boolean = true
    if (flightElementWaypointMission.exitMissionOnRCSignalLost != null) {
      _exitMissionOnRCSignalLost = flightElementWaypointMission.exitMissionOnRCSignalLost
    }

    val missionBuilder: WaypointMission.Builder = WaypointMission.Builder()
      .maxFlightSpeed(_maxFlightSpeed)
      .autoFlightSpeed(_autoFlightSpeed)
      .finishedAction(_finishedAction)
      .headingMode(_headingMode)
      .flightPathMode(_flightPathMode)
      .setGimbalPitchRotationEnabled(_rotateGimbalPitch)
      .setExitMissionOnRCSignalLostEnabled(_exitMissionOnRCSignalLost)
      .gotoFirstWaypointMode(WaypointMissionGotoWaypointMode.POINT_TO_POINT)
      .repeatTimes(1)

    if (flightElementWaypointMission.pointOfInterest != null && flightElementWaypointMission.pointOfInterest.latitude != null && flightElementWaypointMission.pointOfInterest.longitude != null) {
      missionBuilder.pointOfInterest = LocationCoordinate2D(flightElementWaypointMission.pointOfInterest.latitude, flightElementWaypointMission.pointOfInterest.longitude)
    }

    val flightWaypoints = flightElementWaypointMission.waypoints
    if (flightWaypoints != null) {
      var waypoints : MutableList<Waypoint> = ArrayList<Waypoint>()

      for (flightWaypoint in flightWaypoints) {
        val _latitude = flightWaypoint.location?.latitude
        val _longitude = flightWaypoint.location?.longitude
        val _altitude = flightWaypoint.location?.altitude

        if (_latitude != null && _longitude != null && _altitude != null) {
          val waypoint: Waypoint = Waypoint(_latitude, _longitude, _altitude.toFloat())
          waypoint.heading = flightWaypoint.heading?.toInt() ?: 0
          waypoint.cornerRadiusInMeters = flightWaypoint.cornerRadiusInMeters?.toFloat() ?: 5.toFloat()
          waypoint.turnMode = when (flightWaypoint.turnMode) {
            "counterClockwise" -> WaypointTurnMode.COUNTER_CLOCKWISE
            else -> WaypointTurnMode.CLOCKWISE
          }
          waypoint.gimbalPitch = flightWaypoint.gimbalPitch?.toFloat() ?: 0.toFloat()
          waypoint.actionTimeoutInSeconds = 30
          waypoint.actionRepeatTimes = 1

          waypoints.add(waypoint)
        } else {
          Log.d(TAG,"waypointMission - waypoint without location coordinates - skipping")
        }
      }

      missionBuilder.waypointList(waypoints).waypointCount(waypoints.size)

    } else {
      Log.d(TAG,"waypointMission - No waypoints available - exiting.")
    }

    return missionBuilder.build()
  }

  override fun downloadMedia(fileIndex: Long?): String {
    TODO("Not yet implemented")

//    val _dronePlayBackManager = DJISDKManager.getInstance().product?.camera?.playbackManager
//
//    if (_dronePlayBackManager != null) {
//      _dronePlayBackManager.selectAllFiles()
//      _dronePlayBackManager.downloadSelectedFiles(File(Environment.DIRECTORY_DOWNLOADS), object: FileDownloadCallback {
//        override fun onStart() {
//          Log.d(TAG, "Download all media started")
//          _fltSetStatus("Download Started")
//        }
//
//        override fun onEnd() {
//          Log.d(TAG, "Download all media completed successfully")
//          _fltSetStatus("Downloaded")
//        }
//
//        override fun onError(e: Exception) {
//          Log.d(TAG, "Download all media failed")
//          _fltSetStatus("Download Failed")
//        }
//
//        override fun onProgressUpdate(progress: Int) {
//        }
//      })
//
//    } else {
//      Log.d(TAG,"Download all media failed - no Playback Manager")
//      _fltSetStatus("Download Failed")
//    }
  }

  override fun deleteMedia(fileIndex: Long?): Boolean {
    TODO("Not yet implemented")

//    val _dronePlayBackManager = DJISDKManager.getInstance().product?.camera?.playbackManager
//
//    if (_dronePlayBackManager != null) {
//      _fltSetStatus("Delete Started")
//
//      _dronePlayBackManager.selectAllFiles()
//      _dronePlayBackManager.deleteAllSelectedFiles()
//
//      Log.d(TAG,"Delete all media completed")
//      _fltSetStatus("Deleted")
//    } else {
//      Log.d(TAG,"Delete all media failed - no Playback Manager")
//      _fltSetStatus("Delete Failed")
//    }
  }

}

/** Flight Classes */

/*
Note:
Apparently even though you mark something as nullable (optional) in the serializable object, its still considered required.
For it to truly be optional you need to give it a default value.
So, that's why we apply "= null" to each optional property here below.
*/

@Serializable
data class Flight(
  @SerialName("timeline")
  val timeline: List<FlightElement>? = null
)

@Serializable
data class FlightElement(
  @SerialName("type")
  val type: String? = null,
  @SerialName("pointOfInterest")
  val pointOfInterest: FlightLocation? = null,
  @SerialName("maxFlightSpeed")
  val maxFlightSpeed: Double? = null,
  @SerialName("autoFlightSpeed")
  val autoFlightSpeed: Double? = null,
  @SerialName("finishedAction")
  val finishedAction: String? = null,
  @SerialName("headingMode")
  val headingMode: String? = null,
  @SerialName("flightPathMode")
  val flightPathMode: String? = null,
  @SerialName("rotateGimbalPitch")
  val rotateGimbalPitch: Boolean? = null,
  @SerialName("exitMissionOnRCSignalLost")
  val exitMissionOnRCSignalLost: Boolean? = null,
  @SerialName("waypoints")
  val waypoints: List<FlightWaypoint>? = null
)

@Serializable
data class FlightWaypoint(
  @SerialName("location")
  val location: FlightLocation? = null,
  @SerialName("heading")
  val heading: Int? = null,
  @SerialName("cornerRadiusInMeters")
  val cornerRadiusInMeters: Double? = null,
  @SerialName("turnMode")
  val turnMode: String? = null,
  @SerialName("gimbalPitch")
  val gimbalPitch: Double? = null
)

@Serializable
data class FlightLocation(
  @SerialName("altitude")
  val altitude: Double? = null,
  @SerialName("latitude")
  val latitude: Double? = null,
  @SerialName("longitude")
  val longitude: Double? = null
)

@Serializable
data class Vector(
  @SerialName("destinationAltitude")
  val destinationAltitude: Int? = null,
  @SerialName("distanceFromPointOfInterest")
  val distanceFromPointOfInterest: Int? = null,
  @SerialName("headingRelativeToPointOfInterest")
  val headingRelativeToPointOfInterest: Int? = null
)
