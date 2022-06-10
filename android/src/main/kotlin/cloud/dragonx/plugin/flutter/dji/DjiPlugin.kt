  package cloud.dragonx.plugin.flutter.dji

//import dji.midware.util.ContextUtil.getContext

import android.Manifest
import android.app.Activity
import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import androidx.multidex.MultiDex
import com.secneo.sdk.Helper
import dji.common.battery.BatteryState
import dji.common.camera.SettingsDefinitions
import dji.common.error.DJICameraError
import dji.common.error.DJIError
import dji.common.error.DJISDKError
import dji.common.flightcontroller.LocationCoordinate3D
import dji.common.mission.waypoint.*
import dji.common.model.LocationCoordinate2D
import dji.common.util.CommonCallbacks
import dji.sdk.base.BaseComponent
import dji.sdk.base.BaseProduct
import dji.sdk.base.BaseProduct.ComponentKey
import dji.sdk.camera.VideoFeeder
import dji.sdk.camera.VideoFeeder.VideoDataListener
import dji.sdk.flightcontroller.FlightController
import dji.sdk.media.DownloadListener
import dji.sdk.media.MediaFile
import dji.sdk.media.MediaManager.FileListState
import dji.sdk.mission.MissionControl
import dji.sdk.mission.timeline.TimelineElement
import dji.sdk.mission.timeline.TimelineMission
import dji.sdk.mission.timeline.actions.LandAction
import dji.sdk.mission.timeline.actions.RecordVideoAction
import dji.sdk.mission.timeline.actions.ShootPhotoAction
import dji.sdk.mission.timeline.actions.TakeOffAction
import dji.sdk.products.Aircraft
import dji.sdk.sdkmanager.DJISDKInitEvent
import dji.sdk.sdkmanager.DJISDKManager
import dji.sdk.sdkmanager.DJISDKManager.SDKManagerCallback
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import java.io.File
import java.nio.ByteBuffer


  /** DjiPlugin */

class DjiPlugin: FlutterPlugin, Messages.DjiHostApi, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel

  // How to get context and activity in Flutter Plugin for android:
  // https://www.jianshu.com/p/eb7df49fdfb1
  private lateinit var djiPluginActivity: Activity
  private lateinit var djiPluginContext: Context

  var fltDjiFlutterApi: Messages.DjiFlutterApi? = null
  val fltDrone = Messages.Drone()
  val fltStream = Messages.Stream()

  private var drone: Aircraft? = null
  private var droneCurrentLocation: LocationCoordinate3D? = null // Note: this is different from DJI SDK iOS where CLLocation.coordinate is used (LocationCoordinate3D in dji-android is the same as CLLocation.coordinate in dji-ios).
  private var mediaFileList: MutableList<MediaFile> = ArrayList<MediaFile>()
  private var videoDataListener: VideoDataListener? = null

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

  private fun _fltSetStatus(status: String) {
    fltDrone.status = status

    djiPluginActivity.runOnUiThread(Runnable {
      fltDjiFlutterApi?.setStatus(fltDrone) {
        Log.d(TAG, "setStatus Closure Success: $status")
      }
    })
  }

  private fun _fltSendVideo(data: ByteArray?) {
    fltStream.data = data

    djiPluginActivity.runOnUiThread(Runnable {
      fltDjiFlutterApi?.sendVideo(fltStream) {
        //Log.d(TAG, "sendVideo Closure Success: ${data?.size}")
      }
    })
  }

  /** Basic Methods **/

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
    //private val isRegistrationInProgress: AtomicBoolean = AtomicBoolean(false)
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

  override fun start(flightJson: String) {
    Log.d(TAG, "Start Flight JSON: $flightJson")

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

    if (MissionControl.getInstance().isTimelineRunning == true) {
      Log.d(TAG, "startFlightTimeline - Timeline already running - attempting to stop it")
      return
    }

    // Set Home Location Coordinates
    if (droneCurrentLocation != null) {
      val droneHomeLocation =
        LocationCoordinate2D(droneCurrentLocation!!.latitude, droneCurrentLocation!!.longitude)
      _droneFlightController.setHomeLocation(droneHomeLocation, null)
      Log.d(
        TAG,
        "startFlightTimeline - Drone Home Location Coordinates: " + droneHomeLocation.latitude + ", " + droneHomeLocation.longitude
      )
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
        // Making sure the MissionControl Timeline is clean
        _missionControl.unscheduleEverything()

        // Listening for DJI Mission Control errors
        _missionControl.removeAllListeners()
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

        // Adding the scheduled elements
        _missionControl.scheduleElements(scheduledElements)

        // Starting the Timeline Mission
        _missionControl.startTimeline()
    } else {
      Log.d(TAG, "startFlightTimeline - No Mission Control or Scheduled Elements")
      return
    }
  }

  /** Waypoint Methods */

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

  /** Media Methods **/

  override fun getMediaList(): MutableList<Messages.Media> {
    var _fltMediaList: MutableList<Messages.Media> = ArrayList<Messages.Media>()

    val _droneCamera = drone?.camera
    if (_droneCamera != null) {
      _droneCamera.setMode(SettingsDefinitions.CameraMode.MEDIA_DOWNLOAD) { error ->
        if (error != null) {
          Log.d(TAG, "Get media list - set camera mode failed with error" + error.description)
          _fltSetStatus("Download Failed")
        } else {
          Log.d(TAG, "Get media list started")

          val _droneMediaManager = _droneCamera.mediaManager
          if (_droneMediaManager != null) {
            // Fetching the Media List from the Drone's SD Card
            if (_droneMediaManager.sdCardFileListState == FileListState.SYNCING || _droneMediaManager.sdCardFileListState == FileListState.DELETING) {
              Log.d(TAG, "Get media list failed - Media Manager is busy")
              _fltSetStatus("Media List Failed")
            } else {
              _droneMediaManager.refreshFileListOfStorageLocation(SettingsDefinitions.StorageLocation.SDCARD) { error ->
                if (error != null) {
                  Log.d(TAG, "Get media list failed: " + error.description)
                  _fltSetStatus("Media List Failed")
                } else {
                  val sdCardMediaFileList = _droneMediaManager.sdCardFileListSnapshot
                  if (sdCardMediaFileList != null && !sdCardMediaFileList.isEmpty()) {
                    Log.d(TAG, "Get media list successful")
                    _fltSetStatus("Got Media List")

                    mediaFileList = sdCardMediaFileList

                    for (mediaFile in sdCardMediaFileList) {
                      val fltMediaListElement = Messages.Media()
                      fltMediaListElement.fileName = mediaFile.fileName
                      fltMediaListElement.fileIndex = mediaFile.index.toLong()

                      _fltMediaList.add(fltMediaListElement)
                      Log.d(TAG, "Get media list - added file " + mediaFile.fileName)
                    }
                  } else {
                    Log.d(TAG, "Get media list failed - list is empty")
                    _fltSetStatus("Media List Failed")
                  }
                }
              }
            }
          } else {
            Log.d(TAG, "Get media list failed - no Media Manager")
            _fltSetStatus("Media List Failed")
          }
        }
      }
    } else {
      Log.d(TAG, "Get media list failed - no Camera object")
      _fltSetStatus("Media List Failed")
    }

    return _fltMediaList
  }

  override fun downloadMedia(fileIndex: Long?): String {
    var _mediaURLString: String = ""
    val _index: Int = fileIndex?.toInt() ?: -1

    if (_index < 0) {
      Log.d(TAG, "Download media failed - invalid index")
      _fltSetStatus("Download Failed")

      return ""
    }

    if (mediaFileList.isEmpty()) {
      Log.d(TAG, "Download media failed - list is empty")
      _fltSetStatus("Download Failed")

      return ""
    }

    val _droneCamera = drone?.camera
    if (_droneCamera != null) {
      _droneCamera.setMode(SettingsDefinitions.CameraMode.MEDIA_DOWNLOAD) { error ->
        if (error != null) {
          Log.d(TAG, "Download media - set camera mode failed with error" + error.description)
          _fltSetStatus("Download Failed")
        } else if (mediaFileList[_index] != null) {
          Log.d(TAG, "Download media started")

          val selectedMedia = mediaFileList[_index]
          val isPhoto =
            selectedMedia.mediaType == MediaFile.MediaType.JPEG || selectedMedia.mediaType == MediaFile.MediaType.TIFF
          var previousOffset: UInt = 0u
          var fileData: ByteBuffer?
          var currentProgress = -1

          val destDownloadDir = File(djiPluginContext.getExternalFilesDir(null)?.path.toString() + "/dji_media/")

          selectedMedia.fetchFileData(destDownloadDir, null, object: DownloadListener<String> {
            override fun onFailure(error: DJIError) {
              Log.d(TAG, "Download media failed - Fetch File Data: " + error.description)
              _fltSetStatus("Download Failed")
              currentProgress = -1
            }

            override fun onProgress(total: Long, current: Long) {}
            override fun onRateUpdate(total: Long, current: Long, persize: Long) {
              val progress = (current * 1F / total * 100).toInt()
              if (progress != currentProgress) {
                _fltSetStatus(progress.toString() + "%")
                currentProgress = progress
              }
            }

            override fun onStart() {
              currentProgress = -1

              Log.d(TAG, "Download media started")
              _fltSetStatus("Download Started")
            }

            override fun onSuccess(filePath: String) {
              currentProgress = -1

              Log.d(TAG, "Download media completed: $filePath")
              _fltSetStatus("Downloaded")
            }

            override fun onRealtimeDataUpdate(p0: ByteArray?, p1: Long, p2: Boolean) {
            }
          })
        } else {
          Log.d(TAG, "Download media - file not found")
          _fltSetStatus("Download Failed")
        }
      }
    }

    return _mediaURLString
  }

  override fun deleteMedia(fileIndex: Long?): Boolean {
    var _success: Boolean = false
    val _index: Int = fileIndex?.toInt() ?: -1

    if (_index < 0) {
      Log.d(TAG, "Delete media failed - invalid index")
      _fltSetStatus("Delete Failed")

      return false
    }

    if (mediaFileList.isEmpty()) {
      Log.d(TAG, "Download media failed - list is empty")
      _fltSetStatus("Delete Failed")

      return false
    }
    val _droneCamera = drone?.camera
    if (_droneCamera != null) {
      _droneCamera.setMode(SettingsDefinitions.CameraMode.MEDIA_DOWNLOAD) { error ->
        if (error != null) {
          Log.d(TAG, "Delete media - set camera mode failed with error: " + error.description)
          _fltSetStatus("Delete Failed")
        } else if (mediaFileList[_index] != null) {
          Log.d(TAG, "Delete media started")

          val selectedMedia = mediaFileList[_index]
          val filesToDelete = ArrayList<MediaFile>()
          filesToDelete.add(selectedMedia)

          val _droneMediaManager = _droneCamera.mediaManager
          if (_droneMediaManager != null) {
            _droneMediaManager.deleteFiles(
              filesToDelete,
              object :
                CommonCallbacks.CompletionCallbackWithTwoParam<List<MediaFile?>?, DJICameraError?> {
                override fun onSuccess(x: List<MediaFile?>?, y: DJICameraError?) {
                  Log.d(TAG, "Delete media completed")
                  _fltSetStatus("Deleted")
                  _success = true
                }

                override fun onFailure(error: DJIError) {
                  Log.d(TAG, "Delete media failed: " + error.description)
                  _fltSetStatus("Delete Failed")
                  _success = false
                }
              })
          }
        } else {
          Log.d(TAG, "Delete media - file not found")
          _fltSetStatus("Delete Failed")
        }
      }
    }

    return _success
  }

  /** Video Feed Methods **/

  override fun videoFeedStart() {
    videoDataListener = VideoDataListener { bytes, _ ->
      _fltSendVideo(bytes)
    }
    VideoFeeder.getInstance().primaryVideoFeed.addVideoDataListener(videoDataListener!!)
  }

  override fun videoFeedStop() {
    VideoFeeder.getInstance().primaryVideoFeed.removeVideoDataListener(videoDataListener)
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
