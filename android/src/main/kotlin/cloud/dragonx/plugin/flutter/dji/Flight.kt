package cloud.dragonx.plugin.flutter.dji

import org.json.JSONArray
import org.json.JSONObject

/** The flight timeline sent by `Dji.start` as JSON (see lib/flight.dart). */
data class Flight(
  val timeline: List<FlightElement>?
) {
  companion object {
    /** Throws [org.json.JSONException] when the JSON is malformed. */
    fun fromJson(json: String): Flight {
      val root = JSONObject(json)
      return Flight(timeline = root.optJSONArray("timeline")?.objects()?.map(FlightElement::fromJson))
    }
  }
}

data class FlightElement(
  val type: String?,
  val pointOfInterest: FlightLocation?,
  val maxFlightSpeed: Double?,
  val autoFlightSpeed: Double?,
  val finishedAction: String?,
  val headingMode: String?,
  val flightPathMode: String?,
  val rotateGimbalPitch: Boolean?,
  val exitMissionOnRCSignalLost: Boolean?,
  val waypoints: List<FlightWaypoint>?
) {
  companion object {
    fun fromJson(json: JSONObject) = FlightElement(
      type = json.stringOrNull("type"),
      pointOfInterest = json.optJSONObject("pointOfInterest")?.let(FlightLocation::fromJson),
      maxFlightSpeed = json.doubleOrNull("maxFlightSpeed"),
      autoFlightSpeed = json.doubleOrNull("autoFlightSpeed"),
      finishedAction = json.stringOrNull("finishedAction"),
      headingMode = json.stringOrNull("headingMode"),
      flightPathMode = json.stringOrNull("flightPathMode"),
      rotateGimbalPitch = json.booleanOrNull("rotateGimbalPitch"),
      exitMissionOnRCSignalLost = json.booleanOrNull("exitMissionOnRCSignalLost"),
      waypoints = json.optJSONArray("waypoints")?.objects()?.map(FlightWaypoint::fromJson),
    )
  }
}

data class FlightWaypoint(
  val location: FlightLocation?,
  val heading: Int?,
  val cornerRadiusInMeters: Double?,
  val turnMode: String?,
  val gimbalPitch: Double?
) {
  companion object {
    fun fromJson(json: JSONObject) = FlightWaypoint(
      location = json.optJSONObject("location")?.let(FlightLocation::fromJson),
      heading = json.doubleOrNull("heading")?.toInt(),
      cornerRadiusInMeters = json.doubleOrNull("cornerRadiusInMeters"),
      turnMode = json.stringOrNull("turnMode"),
      gimbalPitch = json.doubleOrNull("gimbalPitch"),
    )
  }
}

data class FlightLocation(
  val altitude: Double?,
  val latitude: Double?,
  val longitude: Double?
) {
  companion object {
    fun fromJson(json: JSONObject) = FlightLocation(
      altitude = json.doubleOrNull("altitude"),
      latitude = json.doubleOrNull("latitude"),
      longitude = json.doubleOrNull("longitude"),
    )
  }
}

private fun JSONArray.objects(): List<JSONObject> = (0 until length()).mapNotNull { optJSONObject(it) }

private fun JSONObject.stringOrNull(name: String): String? = if (isNull(name)) null else optString(name)

private fun JSONObject.doubleOrNull(name: String): Double? = if (isNull(name)) null else optDouble(name).takeUnless { it.isNaN() }

private fun JSONObject.booleanOrNull(name: String): Boolean? = if (isNull(name)) null else optBoolean(name)
