package cloud.dragonx.plugin.flutter.dji

import android.content.Context
import android.os.BatteryManager
import android.util.Log
import com.dji.wpmzsdk.manager.WPMZManager
import dji.sdk.keyvalue.key.BatteryKey
import dji.sdk.keyvalue.key.CameraKey
import dji.sdk.keyvalue.key.DJIKey
import dji.sdk.keyvalue.key.DJIKeyInfo
import dji.sdk.keyvalue.key.FlightControllerKey
import dji.sdk.keyvalue.key.GimbalKey
import dji.sdk.keyvalue.value.camera.CameraMode
import dji.sdk.keyvalue.value.camera.CameraStorageLocation
import dji.sdk.keyvalue.value.common.ComponentIndexType
import dji.sdk.keyvalue.value.flightcontroller.FlightCoordinateSystem
import dji.sdk.keyvalue.value.flightcontroller.FlightMode
import dji.sdk.keyvalue.value.flightcontroller.RollPitchControlMode
import dji.sdk.keyvalue.value.flightcontroller.VerticalControlMode
import dji.sdk.keyvalue.value.flightcontroller.VirtualStickFlightControlParam
import dji.sdk.keyvalue.value.flightcontroller.YawControlMode
import dji.sdk.keyvalue.value.gimbal.GimbalAngleRotation
import dji.sdk.keyvalue.value.gimbal.GimbalAngleRotationMode
import dji.v5.common.callback.CommonCallbacks
import dji.v5.common.error.IDJIError
import dji.v5.common.register.DJISDKInitEvent
import dji.v5.et.create
import dji.v5.et.get
import dji.v5.manager.KeyManager
import dji.v5.manager.SDKManager
import dji.v5.manager.aircraft.virtualstick.Stick
import dji.v5.manager.aircraft.virtualstick.VirtualStickManager
import dji.v5.manager.aircraft.waypoint3.WaypointMissionExecuteStateListener
import dji.v5.manager.aircraft.waypoint3.WaypointMissionManager
import dji.v5.manager.aircraft.waypoint3.model.WaypointMissionExecuteState
import dji.v5.manager.datacenter.MediaDataCenter
import dji.v5.manager.datacenter.media.MediaFile
import dji.v5.manager.datacenter.media.MediaFileDownloadListener
import dji.v5.manager.datacenter.media.MediaFileListDataSource
import dji.v5.manager.datacenter.media.PullMediaFileListParam
import dji.v5.manager.interfaces.ICameraStreamManager
import dji.v5.manager.interfaces.SDKManagerCallback
import dji.v5.network.DJINetworkManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.math.roundToInt
import kotlin.math.sqrt
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeout
import org.json.JSONException

/** DjiPlugin – the Android host side of the plugin, built on DJI MSDK v5. */
class DjiPlugin : FlutterPlugin, DjiHostApi {
  private lateinit var context: Context
  private var flutterApi: DjiFlutterApi? = null
  // All plugin state is read and written on the main thread; DJI callbacks hop onto it through this scope.
  private var scope: CoroutineScope = MainScope()

  private var fltDrone = Drone()
  private var sdkInitStarted = false
  private var sdkInitialized = false
  private var virtualStickEnabled = false
  private var mediaPlaybackEnabled = false
  private var mediaFileList: List<MediaFile> = emptyList()
  private var timelineJob: Job? = null
  private var videoFrameListener: ICameraStreamManager.CameraFrameListener? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    scope = MainScope()
    DjiHostApi.setUp(binding.binaryMessenger, this)
    flutterApi = DjiFlutterApi(binding.binaryMessenger)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    DjiHostApi.setUp(binding.binaryMessenger, null)
    flutterApi = null
    if (sdkInitialized) {
      KeyManager.getInstance().cancelListen(this)
    }
    scope.cancel()
  }

  /** Status reporting **/

  private fun report(status: String, error: String = "") {
    scope.launch {
      fltDrone = fltDrone.copy(status = status, error = error)
      sendStatus()
    }
  }

  private fun fail(status: String, message: String) {
    Log.d(TAG, "$status: $message")
    report(status, message)
  }

  private fun updateDrone(update: (Drone) -> Drone) {
    scope.launch {
      fltDrone = update(fltDrone)
      sendStatus()
    }
  }

  private suspend fun sendStatus() {
    try {
      flutterApi?.setStatus(fltDrone)
    } catch (e: FlutterError) {
      Log.d(TAG, "setStatus failed: ${e.message}")
    }
  }

  /** Basic Methods **/

  override fun getPlatformVersion(): Version {
    return Version(string = "Android ${android.os.Build.VERSION.RELEASE}")
  }

  override fun getBatteryLevel(): Battery {
    // The host (mobile device) battery level, matching the iOS implementation.
    val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
    return Battery(level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY).toLong())
  }

  override fun registerApp() {
    Log.d(TAG, "Register App Started")
    if (sdkInitialized) {
      SDKManager.getInstance().registerApp()
      return
    }
    if (sdkInitStarted) return

    try {
      SDKManager.getInstance().init(context, sdkManagerCallback)
    } catch (e: LinkageError) {
      // Thrown when DjiApplication did not install the SDK before its classes were loaded.
      fail("Error", "DJI SDK is not installed. Set android:name=\"cloud.dragonx.plugin.flutter.dji.DjiApplication\" on <application> in AndroidManifest.xml. (${e.message})")
      return
    }
    sdkInitStarted = true
    WPMZManager.getInstance().init(context)

    // Registration needs internet access. As in DJI's sample, retry once the network becomes available.
    DJINetworkManager.getInstance().addNetworkStatusListener { isAvailable ->
      if (sdkInitialized && isAvailable && !SDKManager.getInstance().isRegistered) {
        SDKManager.getInstance().registerApp()
      }
    }
  }

  private val sdkManagerCallback = object : SDKManagerCallback {
    override fun onRegisterSuccess() {
      Log.d(TAG, "Register Success")
      report("Registered")
    }

    override fun onRegisterFailure(error: IDJIError) {
      fail("Error", "Register app failed: ${error.message()}")
    }

    override fun onProductConnect(productId: Int) {
      Log.d(TAG, "Product Connected: $productId")
      report("Connected")
    }

    override fun onProductDisconnect(productId: Int) {
      Log.d(TAG, "Product Disconnected: $productId")
      scope.launch { virtualStickEnabled = false }
      report("Disconnected")
    }

    override fun onProductChanged(productId: Int) {
      Log.d(TAG, "Product Changed: $productId")
    }

    override fun onInitProcess(event: DJISDKInitEvent, totalProcess: Int) {
      if (event == DJISDKInitEvent.INITIALIZE_COMPLETE) {
        scope.launch {
          sdkInitialized = true
          SDKManager.getInstance().registerApp()
        }
      }
    }

    override fun onDatabaseDownloadProgress(current: Long, total: Long) {}
  }

  override fun connectDrone() {
    // MSDK v5 connects to the aircraft automatically once the app is registered; report the current state.
    Log.d(TAG, "Connect Drone Started")
    if (!sdkInitialized) {
      fail("Error", "Connect drone failed - call registerApp first")
      return
    }
    val connected = getValue(FlightControllerKey.KeyConnection, false)
    report(if (connected) "Connected" else "Disconnected")
  }

  override fun disconnectDrone() {
    fail("Error", "Disconnect drone is not supported by DJI MSDK v5 - the SDK manages the connection")
  }

  override fun delegateDrone() {
    Log.d(TAG, "Delegate Drone Started")
    if (!sdkInitialized) {
      fail("Error", "Delegations - DJI SDK is not initialized - call registerApp first")
      return
    }

    val keyManager = KeyManager.getInstance()
    keyManager.cancelListen(this)

    keyManager.listen(FlightControllerKey.KeyAircraftLocation3D.create(), this) { _, location ->
      if (location != null) {
        updateDrone {
          it.copy(latitude = location.latitude, longitude = location.longitude, altitude = location.altitude)
        }
      }
    }
    keyManager.listen(FlightControllerKey.KeyAircraftVelocity.create(), this) { _, velocity ->
      if (velocity != null) {
        updateDrone { it.copy(speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)) }
      }
    }
    keyManager.listen(FlightControllerKey.KeyAircraftAttitude.create(), this) { _, attitude ->
      if (attitude != null) {
        updateDrone { it.copy(roll = attitude.roll, pitch = attitude.pitch, yaw = attitude.yaw) }
      }
    }
    keyManager.listen(BatteryKey.KeyChargeRemainingInPercent.create(), this) { _, percent ->
      if (percent != null) {
        updateDrone { it.copy(batteryPercent = percent.toDouble()) }
      }
    }
    // Confirm Landing, as the DJI SDK v4 implementation did.
    keyManager.listen(FlightControllerKey.KeyIsLandingConfirmationNeeded.create(), this) { _, needed ->
      if (needed == true) {
        scope.launch {
          try {
            FlightControllerKey.KeyConfirmLanding.create().perform()
          } catch (e: DjiException) {
            Log.d(TAG, "Confirm landing failed: ${e.message}")
          }
        }
      }
    }

    Log.d(TAG, "Delegations completed")
    report("Delegated")
  }

  override fun takeOff() {
    Log.d(TAG, "Takeoff Started")
    report("Takeoff")
    scope.launch {
      try {
        FlightControllerKey.KeyStartTakeoff.create().perform()
      } catch (e: DjiException) {
        fail("Takeoff Failed", "Takeoff Failed - ${e.message}")
      }
    }
  }

  override fun land() {
    Log.d(TAG, "Land Started")
    report("Land")
    scope.launch {
      try {
        FlightControllerKey.KeyStartAutoLanding.create().perform()
      } catch (e: DjiException) {
        fail("Land Failed", "Land Failed - ${e.message}")
      }
    }
  }

  /** Mobile Remote Controller **/
  // MSDK v5 has no mobile remote controller; its virtual stick positions replace it.

  override fun mobileRemoteController(
    enabled: Boolean,
    leftStickHorizontal: Double,
    leftStickVertical: Double,
    rightStickHorizontal: Double,
    rightStickVertical: Double
  ) {
    scope.launch {
      try {
        if (!enabled) {
          disableVirtualStick()
          report("Mobile Remote")
          return@launch
        }
        enableVirtualStick(advancedMode = false)
        val manager = VirtualStickManager.getInstance()
        manager.leftStick.horizontalPosition = stickPosition(leftStickHorizontal)
        manager.leftStick.verticalPosition = stickPosition(leftStickVertical)
        manager.rightStick.horizontalPosition = stickPosition(rightStickHorizontal)
        manager.rightStick.verticalPosition = stickPosition(rightStickVertical)
        report("Mobile Remote")
      } catch (e: DjiException) {
        fail("Mobile Remote Failed", "Mobile Remote failed with error ${e.message}")
      }
    }
  }

  /** Converts a DJI SDK v4 stick value in [-1, 1] to an MSDK v5 stick position. */
  private fun stickPosition(value: Double): Int =
    (value.coerceIn(-1.0, 1.0) * Stick.MAX_STICK_POSITION_ABS).roundToInt()

  /** Virtual Stick Methods **/

  override fun virtualStick(
    enabled: Boolean,
    pitch: Double,
    roll: Double,
    yaw: Double,
    verticalThrottle: Double
  ) {
    scope.launch {
      try {
        if (!enabled) {
          disableVirtualStick()
          report("Virtual Stick")
          return@launch
        }
        enableVirtualStick(advancedMode = true)
        // The same control modes the DJI SDK v4 implementation used.
        val param = VirtualStickFlightControlParam().apply {
          this.pitch = pitch
          this.roll = roll
          this.yaw = yaw
          this.verticalThrottle = verticalThrottle
          rollPitchCoordinateSystem = FlightCoordinateSystem.BODY
          rollPitchControlMode = RollPitchControlMode.ANGLE
          yawControlMode = YawControlMode.ANGLE
          verticalControlMode = VerticalControlMode.POSITION
        }
        VirtualStickManager.getInstance().sendVirtualStickAdvancedParam(param)
        report("Virtual Stick")
      } catch (e: DjiException) {
        fail("Virtual Stick Failed", "Enable Virtual Stick failed with error ${e.message}")
      }
    }
  }

  private suspend fun enableVirtualStick(advancedMode: Boolean) {
    val manager = VirtualStickManager.getInstance()
    if (!virtualStickEnabled) {
      awaitCompletion { manager.enableVirtualStick(it) }
      virtualStickEnabled = true
    }
    manager.setVirtualStickAdvancedModeEnabled(advancedMode)
  }

  private suspend fun disableVirtualStick() {
    if (!virtualStickEnabled) return
    awaitCompletion { VirtualStickManager.getInstance().disableVirtualStick(it) }
    virtualStickEnabled = false
  }

  /** Gimbal Methods **/

  override fun gimbalRotatePitch(degrees: Double) {
    val rotation = GimbalAngleRotation().apply {
      mode = GimbalAngleRotationMode.ABSOLUTE_ANGLE
      pitch = degrees
      rollIgnored = true
      yawIgnored = true
      duration = 1.0
    }
    scope.launch {
      try {
        GimbalKey.KeyRotateByAngle.create(ComponentIndexType.LEFT_OR_MAIN).perform(rotation)
        report("Gimbal Rotated")
      } catch (e: DjiException) {
        fail("Gimbal Failed", "Gimbal Rotate failed with error ${e.message}")
      }
    }
  }

  /** Timeline Methods **/
  // MSDK v5 has no MissionControl timeline, so the plugin runs the elements one after another.

  override fun start(flightJson: String) {
    Log.d(TAG, "Start Flight JSON: $flightJson")

    val flight = try {
      Flight.fromJson(flightJson)
    } catch (e: JSONException) {
      fail("Start Failed", "Error - Failed to parse Flight JSON: ${e.message}")
      return
    }

    val timeline = flight.timeline
    if (timeline.isNullOrEmpty()) {
      fail("Start Failed", "startFlightTimeline - Timeline List is empty")
      return
    }
    if (timelineJob?.isActive == true) {
      fail("Start Failed", "startFlightTimeline - Timeline already running")
      return
    }

    timelineJob = scope.launch {
      try {
        // Set Home Location Coordinates (best effort, as in the DJI SDK v4 implementation)
        try {
          FlightControllerKey.KeyHomeLocationUsingCurrentAircraftLocation.create().perform()
        } catch (e: DjiException) {
          Log.d(TAG, "startFlightTimeline - setting the home location failed: ${e.message}")
        }

        report("Started")
        for (element in timeline) {
          runTimelineElement(element)
        }
        report("Timeline Finished")
      } catch (e: DjiException) {
        fail("Start Failed", "Timeline Failed - ${e.message}")
      }
    }
  }

  private suspend fun runTimelineElement(element: FlightElement) {
    Log.d(TAG, "Timeline element: ${element.type}")
    when (element.type) {
      "takeOff" -> {
        FlightControllerKey.KeyStartTakeoff.create().perform()
        // Takeoff is complete once the aircraft is flying and has left the automatic takeoff mode.
        waitUntil(TAKEOFF_TIMEOUT_MS) {
          getValue(FlightControllerKey.KeyIsFlying, false) &&
            getValue(FlightControllerKey.KeyFlightMode, FlightMode.UNKNOWN) != FlightMode.AUTO_TAKE_OFF
        }
      }

      "land" -> {
        FlightControllerKey.KeyStartAutoLanding.create().perform()
        waitUntil(LANDING_TIMEOUT_MS) { !getValue(FlightControllerKey.KeyIsFlying, true) }
      }

      "waypointMission" -> runWaypointMission(element)

      "singleShootPhoto" -> {
        setCameraMode(CameraMode.PHOTO_NORMAL)
        CameraKey.KeyStartShootPhoto.create(ComponentIndexType.LEFT_OR_MAIN).perform()
      }

      "startRecordVideo" -> {
        setCameraMode(CameraMode.VIDEO_NORMAL)
        CameraKey.KeyStartRecord.create(ComponentIndexType.LEFT_OR_MAIN).perform()
      }

      "stopRecordVideo" -> CameraKey.KeyStopRecord.create(ComponentIndexType.LEFT_OR_MAIN).perform()

      else -> Log.d(TAG, "Timeline element ${element.type} is not supported - skipping")
    }
  }

  /** Waypoint Methods */

  private suspend fun runWaypointMission(element: FlightElement) {
    val kmzFile = File(context.cacheDir, "dji_waypoints/$WAYPOINT_MISSION_NAME.kmz")
    if (WaypointKmz.generate(kmzFile, element) == 0) {
      throw DjiException("waypointMission - No waypoints available")
    }

    val manager = WaypointMissionManager.getInstance()
    suspendCancellableCoroutine { continuation ->
      manager.pushKMZFileToAircraft(kmzFile.path, object : CommonCallbacks.CompletionCallbackWithProgress<Double> {
        override fun onProgressUpdate(progress: Double) {}
        override fun onSuccess() {
          if (continuation.isActive) continuation.resume(Unit)
        }
        override fun onFailure(error: IDJIError) {
          if (continuation.isActive) continuation.resumeWithException(DjiException(error))
        }
      })
    }

    // Completes when the mission finishes, or fails when it stops early.
    var executing = false
    suspendCancellableCoroutine { continuation ->
      val listener = object : WaypointMissionExecuteStateListener {
        override fun onMissionStateUpdate(state: WaypointMissionExecuteState) {
          when (state) {
            WaypointMissionExecuteState.EXECUTING -> executing = true
            WaypointMissionExecuteState.FINISHED -> finish(null)
            WaypointMissionExecuteState.DISCONNECTED,
            WaypointMissionExecuteState.NOT_SUPPORTED -> finish("Waypoint mission stopped: $state")
            WaypointMissionExecuteState.IDLE,
            WaypointMissionExecuteState.READY -> if (executing) finish("Waypoint mission stopped before finishing")
            else -> {}
          }
        }

        fun finish(error: String?) {
          manager.removeWaypointMissionExecuteStateListener(this)
          if (!continuation.isActive) return
          if (error == null) continuation.resume(Unit) else continuation.resumeWithException(DjiException(error))
        }
      }
      manager.addWaypointMissionExecuteStateListener(listener)
      continuation.invokeOnCancellation { manager.removeWaypointMissionExecuteStateListener(listener) }

      manager.startMission(
        WAYPOINT_MISSION_NAME,
        manager.getAvailableWaylineIDs(kmzFile.path),
        object : CommonCallbacks.CompletionCallback {
          override fun onSuccess() {}
          override fun onFailure(error: IDJIError) {
            listener.finish("Start waypoint mission failed: ${error.message()}")
          }
        })
    }
  }

  /** Media Methods **/

  override suspend fun getMediaList(): List<Media> {
    return try {
      enableMediaPlayback()
      val mediaManager = MediaDataCenter.getInstance().mediaManager
      awaitCompletion {
        // -1 / -1: from the latest file, all files (as in DJI's sample).
        mediaManager.pullMediaFileListFromCamera(PullMediaFileListParam.Builder().mediaFileIndex(-1).count(-1).build(), it)
      }
      mediaFileList = mediaManager.mediaFileListData.data.orEmpty()
      if (mediaFileList.isEmpty()) {
        fail("Media List Failed", "Get media list failed - list is empty")
        return emptyList()
      }
      report("Got Media List")
      mediaFileList.map { Media(fileName = it.fileName, fileIndex = it.fileIndex.toLong()) }
    } catch (e: DjiException) {
      fail("Media List Failed", "Get media list failed: ${e.message}")
      emptyList()
    }
  }

  override suspend fun downloadMedia(fileIndex: Long): String {
    val mediaFile = mediaFileList.getOrNull(fileIndex.toInt())
    if (mediaFile == null) {
      fail("Download Failed", "Download media failed - file not found (call getMediaList first)")
      return ""
    }

    return try {
      enableMediaPlayback()
      val destination = File(context.getExternalFilesDir(null), "dji_media/${mediaFile.fileName}")
      destination.parentFile?.mkdirs()
      destination.delete()
      pullMediaFile(mediaFile, destination)
      Log.d(TAG, "Download media completed: ${destination.path}")
      report("Downloaded")
      destination.path
    } catch (e: DjiException) {
      fail("Download Failed", "Download media failed - Fetch File Data: ${e.message}")
      ""
    } catch (e: IOException) {
      fail("Download Failed", "Download media failed to write the file: ${e.message}")
      ""
    }
  }

  private suspend fun pullMediaFile(mediaFile: MediaFile, destination: File) {
    val output = BufferedOutputStream(FileOutputStream(destination))
    try {
      suspendCancellableCoroutine { continuation ->
        var currentProgress = -1
        mediaFile.pullOriginalMediaFileFromCamera(0, object : MediaFileDownloadListener {
          override fun onStart() {
            report("Download Started")
          }

          override fun onProgress(total: Long, current: Long) {
            val progress = if (total > 0) (current * 100 / total).toInt() else 0
            if (progress != currentProgress) {
              currentProgress = progress
              report("$progress%")
            }
          }

          override fun onRealtimeDataUpdate(data: ByteArray, position: Long) {
            output.write(data)
          }

          override fun onFinish() {
            if (continuation.isActive) continuation.resume(Unit)
          }

          override fun onFailure(error: IDJIError) {
            if (continuation.isActive) continuation.resumeWithException(DjiException(error))
          }
        })
      }
    } finally {
      output.close()
    }
  }

  override suspend fun deleteMedia(fileIndex: Long): Boolean {
    val mediaFile = mediaFileList.getOrNull(fileIndex.toInt())
    if (mediaFile == null) {
      fail("Delete Failed", "Delete media failed - file not found (call getMediaList first)")
      return false
    }

    return try {
      enableMediaPlayback()
      awaitCompletion { MediaDataCenter.getInstance().mediaManager.deleteMediaFiles(listOf(mediaFile), it) }
      mediaFileList = mediaFileList - mediaFile
      report("Deleted")
      true
    } catch (e: DjiException) {
      fail("Delete Failed", "Delete media failed: ${e.message}")
      false
    }
  }

  private suspend fun enableMediaPlayback() {
    if (mediaPlaybackEnabled) return
    val mediaManager = MediaDataCenter.getInstance().mediaManager
    mediaManager.setMediaFileDataSource(
      MediaFileListDataSource.Builder()
        .setLocation(CameraStorageLocation.SDCARD)
        .setIndexType(ComponentIndexType.LEFT_OR_MAIN)
        .build()
    )
    awaitCompletion { mediaManager.enable(it) }
    mediaPlaybackEnabled = true
  }

  /** The camera only shoots and records after leaving media playback mode. */
  private suspend fun disableMediaPlayback() {
    if (!mediaPlaybackEnabled) return
    awaitCompletion { MediaDataCenter.getInstance().mediaManager.disable(it) }
    mediaPlaybackEnabled = false
  }

  /** Video Feed Methods **/

  override fun videoFeedStart() {
    if (videoFrameListener != null) {
      report("Video Started")
      return
    }

    // Streams raw I420 (YUV420p) frames, the same format the DJI SDK v4 implementation sent.
    val listener = ICameraStreamManager.CameraFrameListener { data, offset, length, _, _, _ ->
      val frame = data.copyOfRange(offset, offset + length)
      scope.launch {
        try {
          flutterApi?.sendVideo(Stream(data = frame))
        } catch (e: FlutterError) {
          Log.d(TAG, "sendVideo failed: ${e.message}")
        }
      }
    }
    val cameraStreamManager = MediaDataCenter.getInstance().cameraStreamManager
    cameraStreamManager.setKeepAliveDecoding(true)
    cameraStreamManager.addFrameListener(ComponentIndexType.LEFT_OR_MAIN, ICameraStreamManager.FrameFormat.YUV420_888, listener)
    videoFrameListener = listener
    report("Video Started")
  }

  override fun videoFeedStop() {
    val listener = videoFrameListener
    if (listener != null) {
      val cameraStreamManager = MediaDataCenter.getInstance().cameraStreamManager
      cameraStreamManager.removeFrameListener(listener)
      cameraStreamManager.setKeepAliveDecoding(false)
      videoFrameListener = null
    }
    report("Video Stopped")
  }

  override fun videoRecordStart() {
    scope.launch {
      try {
        setCameraMode(CameraMode.VIDEO_NORMAL)
        CameraKey.KeyStartRecord.create(ComponentIndexType.LEFT_OR_MAIN).perform()
        Log.d(TAG, "Video record started")
        report("Record Started")
      } catch (e: DjiException) {
        fail("Record Start Failed", "Video record start failed with error: ${e.message}")
      }
    }
  }

  override fun videoRecordStop() {
    scope.launch {
      try {
        CameraKey.KeyStopRecord.create(ComponentIndexType.LEFT_OR_MAIN).perform()
        Log.d(TAG, "Video record stopped")
        report("Record Stopped")
      } catch (e: DjiException) {
        fail("Record Stop Failed", "Video record stop failed with error: ${e.message}")
      }
    }
  }

  private suspend fun setCameraMode(mode: CameraMode) {
    disableMediaPlayback()
    val key = CameraKey.KeyCameraMode.create(ComponentIndexType.LEFT_OR_MAIN)
    if (key.get() == mode) return
    awaitCompletion { KeyManager.getInstance().setValue(key, mode, it) }
  }

  /** MSDK v5 helpers **/

  private fun <T> getValue(keyInfo: DJIKeyInfo<T>, default: T): T = keyInfo.create().get(default) ?: default

  private suspend fun <P, R> DJIKey.ActionKey<P, R>.perform(param: P? = null): R? =
    suspendCancellableCoroutine { continuation ->
      val callback = object : CommonCallbacks.CompletionCallbackWithParam<R> {
        override fun onSuccess(result: R?) {
          if (continuation.isActive) continuation.resume(result)
        }

        override fun onFailure(error: IDJIError) {
          if (continuation.isActive) continuation.resumeWithException(DjiException(error))
        }
      }
      if (param == null) KeyManager.getInstance().performAction(this, callback)
      else KeyManager.getInstance().performAction(this, param, callback)
    }

  private suspend fun awaitCompletion(start: (CommonCallbacks.CompletionCallback) -> Unit) =
    suspendCancellableCoroutine { continuation ->
      start(object : CommonCallbacks.CompletionCallback {
        override fun onSuccess() {
          if (continuation.isActive) continuation.resume(Unit)
        }

        override fun onFailure(error: IDJIError) {
          if (continuation.isActive) continuation.resumeWithException(DjiException(error))
        }
      })
    }

  private suspend fun waitUntil(timeoutMs: Long, condition: () -> Boolean) {
    try {
      withTimeout(timeoutMs) {
        while (!condition()) delay(POLL_INTERVAL_MS)
      }
    } catch (e: TimeoutCancellationException) {
      throw DjiException("Timed out after ${timeoutMs / 1000}s")
    }
  }

  companion object {
    private const val TAG = "=== DjiPlugin Android"
    private const val WAYPOINT_MISSION_NAME = "dji_flutter_waypoint_mission"
    private const val POLL_INTERVAL_MS = 200L
    private const val TAKEOFF_TIMEOUT_MS = 60_000L
    private const val LANDING_TIMEOUT_MS = 180_000L
  }
}

private fun IDJIError.message(): String = description() ?: hint() ?: errorCode() ?: toString()

internal class DjiException(message: String) : Exception(message) {
  constructor(error: IDJIError) : this(error.message())
}
