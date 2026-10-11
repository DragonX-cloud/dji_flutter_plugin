package cloud.dragonx.plugin.flutter.dji

import com.dji.wpmzsdk.common.data.Template
import com.dji.wpmzsdk.manager.WPMZManager
import dji.sdk.wpmz.value.mission.WaylineAltitudeMode
import dji.sdk.wpmz.value.mission.WaylineCoordinateMode
import dji.sdk.wpmz.value.mission.WaylineCoordinateParam
import dji.sdk.wpmz.value.mission.WaylineDroneInfo
import dji.sdk.wpmz.value.mission.WaylineExitOnRCLostAction
import dji.sdk.wpmz.value.mission.WaylineExitOnRCLostBehavior
import dji.sdk.wpmz.value.mission.WaylineFinishedAction
import dji.sdk.wpmz.value.mission.WaylineFlyToWaylineMode
import dji.sdk.wpmz.value.mission.WaylineLocationCoordinate2D
import dji.sdk.wpmz.value.mission.WaylineLocationCoordinate3D
import dji.sdk.wpmz.value.mission.WaylineMission
import dji.sdk.wpmz.value.mission.WaylineMissionConfig
import dji.sdk.wpmz.value.mission.WaylinePositioningType
import dji.sdk.wpmz.value.mission.WaylineTemplateWaypointInfo
import dji.sdk.wpmz.value.mission.WaylineWaypoint
import dji.sdk.wpmz.value.mission.WaylineWaypointPitchMode
import dji.sdk.wpmz.value.mission.WaylineWaypointTurnMode
import dji.sdk.wpmz.value.mission.WaylineWaypointTurnParam
import dji.sdk.wpmz.value.mission.WaylineWaypointYawMode
import dji.sdk.wpmz.value.mission.WaylineWaypointYawParam
import dji.sdk.wpmz.value.mission.WaylineWaypointYawPathMode
import java.io.File

/**
 * Translates the plugin's waypoint mission (the DJI SDK v4 model exposed to Dart) into a DJI WPML (KMZ) file,
 * which is the only waypoint mission format MSDK v5 accepts.
 *
 * Follows DJI's MSDK v5 sample (KMZTestUtil / WayPointV3Fragment).
 */
internal object WaypointKmz {
  private const val DEFAULT_MAX_FLIGHT_SPEED = 15.0
  private const val DEFAULT_AUTO_FLIGHT_SPEED = 8.0
  private const val DEFAULT_CORNER_RADIUS_IN_METERS = 5.0
  // DJI's default takeoff security height, used when the mission starts on the ground.
  private const val SECURITY_TAKE_OFF_HEIGHT = 20.0

  /** Writes the mission to [kmzFile] and returns the waypoints that were written. */
  fun generate(kmzFile: File, element: FlightElement): Int {
    val waypoints = element.waypoints.orEmpty().mapNotNull { waypoint ->
      val latitude = waypoint.location?.latitude
      val longitude = waypoint.location?.longitude
      val altitude = waypoint.location?.altitude
      if (latitude == null || longitude == null || altitude == null) null
      else Triple(waypoint, WaylineLocationCoordinate2D(latitude, longitude), altitude)
    }
    if (waypoints.isEmpty()) return 0

    val curved = element.flightPathMode != "normal"
    val poi = element.pointOfInterest?.let {
      WaylineLocationCoordinate3D(it.latitude ?: 0.0, it.longitude ?: 0.0, it.altitude ?: 0.0)
    } ?: WaylineLocationCoordinate3D()

    val waylineWaypoints = waypoints.mapIndexed { index, (waypoint, location, altitude) ->
      WaylineWaypoint().apply {
        setWaypointIndex(index)
        setLocation(location)
        setHeight(altitude)
        setEllipsoidHeight(altitude)
        setUseGlobalFlightHeight(false)
        setUseGlobalAutoFlightSpeed(true)
        setUseStraightLine(!curved)
        setGimbalPitchAngle(waypoint.gimbalPitch ?: 0.0)

        setTurnParam(
          WaylineWaypointTurnParam(
            if (curved) WaylineWaypointTurnMode.TO_POINT_AND_PASS_WITH_CONTINUITY_CURVATURE
            else WaylineWaypointTurnMode.TO_POINT_AND_STOP_WITH_DISCONTINUITY_CURVATURE,
            waypoint.cornerRadiusInMeters ?: DEFAULT_CORNER_RADIUS_IN_METERS,
          )
        )
        setIsWaylineWaypointTurnParamSet(true)
        setUseGlobalTurnParam(false)

        setYawParam(yawParam(element.headingMode, waypoint, poi))
        setIsWaylineWaypointYawParamSet(true)
        setUseGlobalYawParam(false)
      }
    }

    val waypointInfo = WaylineTemplateWaypointInfo().apply {
      setWaypoints(waylineWaypoints)
      setActionGroups(emptyList())
      setGlobalFlightHeight(waypoints.first().third)
      setIsGlobalFlightHeightSet(true)
      setGlobalTurnMode(WaylineWaypointTurnMode.TO_POINT_AND_STOP_WITH_DISCONTINUITY_CURVATURE)
      setIsTemplateGlobalTurnModeSet(true)
      setUseStraightLine(!curved)
      setGlobalYawParam(WaylineWaypointYawParam().apply {
        setYawMode(WaylineWaypointYawMode.FOLLOW_WAYLINE)
        setPoiLocation(poi)
      })
      setIsTemplateGlobalYawParamSet(true)
      setPitchMode(
        if (element.rotateGimbalPitch ?: true) WaylineWaypointPitchMode.USE_POINT_SETTING
        else WaylineWaypointPitchMode.MANUALLY
      )
    }

    val template = Template().apply {
      setWaypointInfo(waypointInfo)
      setCoordinateParam(WaylineCoordinateParam().apply {
        setCoordinateMode(WaylineCoordinateMode.WGS84)
        setPositioningType(WaylinePositioningType.GPS)
        setIsWaylinePositioningTypeSet(true)
        // DJI SDK v4 waypoint altitudes are relative to the takeoff point.
        setAltitudeMode(WaylineAltitudeMode.RELATIVE_TO_START_POINT)
      })
      setUseGlobalTransitionalSpeed(true)
      setAutoFlightSpeed(element.autoFlightSpeed ?: DEFAULT_AUTO_FLIGHT_SPEED)
      setPayloadParam(emptyList())
    }

    val exitOnRCSignalLost = element.exitMissionOnRCSignalLost ?: true
    val config = WaylineMissionConfig().apply {
      setFlyToWaylineMode(WaylineFlyToWaylineMode.SAFELY)
      setFinishAction(finishedAction(element.finishedAction))
      setDroneInfo(WaylineDroneInfo())
      setSecurityTakeOffHeight(SECURITY_TAKE_OFF_HEIGHT)
      setIsSecurityTakeOffHeightSet(true)
      setExitOnRCLostBehavior(
        if (exitOnRCSignalLost) WaylineExitOnRCLostBehavior.EXCUTE_RC_LOST_ACTION
        else WaylineExitOnRCLostBehavior.GO_ON
      )
      setExitOnRCLostType(WaylineExitOnRCLostAction.GO_BACK)
      // WPML has no maximum speed; the closest equivalent is the speed used to fly to the first waypoint.
      setGlobalTransitionalSpeed(element.maxFlightSpeed ?: DEFAULT_MAX_FLIGHT_SPEED)
      setPayloadInfo(emptyList())
    }

    val now = System.currentTimeMillis().toDouble()
    val mission = WaylineMission().apply {
      setCreateTime(now)
      setUpdateTime(now)
    }

    kmzFile.parentFile?.mkdirs()
    kmzFile.delete()
    WPMZManager.getInstance().generateKMZFile(kmzFile.path, mission, config, template)
    return waylineWaypoints.size
  }

  private fun yawParam(headingMode: String?, waypoint: FlightWaypoint, poi: WaylineLocationCoordinate3D) =
    WaylineWaypointYawParam().apply {
      when (headingMode) {
        "auto" -> setYawMode(WaylineWaypointYawMode.FOLLOW_WAYLINE)
        "towardPointOfInterest" -> setYawMode(WaylineWaypointYawMode.TOWARD_POI)
        else -> {
          setYawMode(WaylineWaypointYawMode.SMOOTH_TRANSITION)
          setEnableYawAngle(true)
          setYawAngle((waypoint.heading ?: 0).toDouble())
        }
      }
      setYawPathMode(
        if (waypoint.turnMode == "counterClockwise") WaylineWaypointYawPathMode.COUNTER_CLOCKWISE
        else WaylineWaypointYawPathMode.CLOCKWISE
      )
      setPoiLocation(poi)
    }

  private fun finishedAction(finishedAction: String?) = when (finishedAction) {
    "autoLand" -> WaylineFinishedAction.AUTO_LAND
    "goHome" -> WaylineFinishedAction.GO_HOME
    "goFirstWaypoint" -> WaylineFinishedAction.GOTO_FIRST_WAYPOINT
    // WPML has no "continue until stop"; the aircraft hovers at the last waypoint, as with "noAction".
    else -> WaylineFinishedAction.NO_ACTION
  }
}
