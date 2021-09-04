// Flight (Timeline)

class Flight {
  final List<FlightElement> timeline;

  Flight(this.timeline);

  Flight.fromJson(Map<String, dynamic> json) : this.timeline = json['timeline'];

  Map<String, dynamic> toJson() => {
        'timeline': timeline,
      };
}

enum FlightElementType {
  takeOff, // 'DJITakeOffAction';
  land, // 'DJILandAction';
  goto, // 'DJIGoToAction';
  home, // 'DJIGoHomeAction';
  hotpoint, // 'hotPointAction';
  waypointMission, // 'waypointMission';
}

// Flight Element

class FlightElement {
  final FlightElementType type;

  FlightElement({required this.type});

  FlightElement.fromJson(Map<String, dynamic> json) : this.type = json['type'];

  Map<String, dynamic> toJson() => {
        'type': type,
      };
}

// Waypoint

enum FlightWaypointTurnMode {
  clockwise,
  counterClockwise,
}

class FlightWaypoint {
  final double longitude;
  final double latitude;
  final double altitude;
  final int
      heading; // -180..180 degrees; Relevant only if flightWaypointMissionHeadingMode is FlightWaypointMissionHeadingMode.usingWaypointHeading;
  final double cornerRadiusInMeters;
  final FlightWaypointTurnMode turnMode;
  final double
      gimbalPitch; // The final position of the gimbal, when the drone reaches the endpoint; Relevant only if rotateGimbalPitch is TRUE;

  FlightWaypoint({
    required this.longitude,
    required this.latitude,
    required this.altitude,
    this.heading = 0,
    this.cornerRadiusInMeters = 2,
    this.turnMode = FlightWaypointTurnMode.clockwise,
    this.gimbalPitch = 0,
  });

  FlightWaypoint.fromJson(Map<String, dynamic> json)
      : this.longitude = json['longitude'],
        this.latitude = json['latitude'],
        this.altitude = json['altitude'],
        this.heading = json['heading'],
        this.cornerRadiusInMeters = json['cornerRadiusInMeters'],
        this.turnMode = json['turnMode'],
        this.gimbalPitch = json['gimbalPitch'];

  Map<String, dynamic> toJson() => {
        'longitude': longitude,
        'latitude': latitude,
        'altitude': altitude,
        'heading': heading,
        'cornerRadiusInMeters': cornerRadiusInMeters,
        'turnMode': turnMode,
        'gimbalPitch': gimbalPitch,
      };
}

// Waypoint Mission

enum FlightWaypointMissionHeadingMode {
  auto,
  towardPointOfInterest,
  usingWaypointHeading,
}

enum FlightWaypointMissionPathMode {
  normal,
  curved,
}

enum FlightWaypointMissionFinishedAction {
  noAction,
  autoLand,
  continueUntilStop,
  goFirstWaypoint,
  goHome,
}

class FlightElementWaypointMission extends FlightElement {
  final double maxFlightSpeed;
  final double autoFlightSpeed;
  final FlightWaypointMissionFinishedAction finishedAction;
  final FlightWaypointMissionHeadingMode headingMode;
  final FlightWaypointMissionPathMode flightPathMode;
  final bool rotateGimbalPitch;
  final bool exitMissionOnRCSignalLost;

  final List<FlightWaypoint> waypoints;

  FlightElementWaypointMission({
    this.maxFlightSpeed = 15.0,
    this.autoFlightSpeed = 8.0,
    this.finishedAction = FlightWaypointMissionFinishedAction.noAction,
    this.headingMode = FlightWaypointMissionHeadingMode.usingWaypointHeading,
    this.flightPathMode = FlightWaypointMissionPathMode.curved,
    this.rotateGimbalPitch = true,
    this.exitMissionOnRCSignalLost = true,
    required this.waypoints,
  }) : super(type: FlightElementType.waypointMission);

  FlightElementWaypointMission.fromJson(Map<String, dynamic> json)
      : this.maxFlightSpeed = json['maxFlightSpeed'],
        this.autoFlightSpeed = json['autoFlightSpeed'],
        this.finishedAction = json['finishedAction'],
        this.headingMode = json['headingMode'],
        this.flightPathMode = json['flightPathMode'],
        this.rotateGimbalPitch = json['rotateGimbalPitch'],
        this.exitMissionOnRCSignalLost = json['exitMissionOnRCSignalLost'],
        this.waypoints = json['waypoints'],
        super(type: FlightElementType.waypointMission);

  Map<String, dynamic> toJson() => {
        'type': type,
        'maxFlightSpeed': maxFlightSpeed,
        'autoFlightSpeed': autoFlightSpeed,
        'finishedAction': finishedAction,
        'headingMode': headingMode,
        'flightPathMode': flightPathMode,
        'rotateGimbalPitch': rotateGimbalPitch,
        'exitMissionOnRCSignalLost': exitMissionOnRCSignalLost,
        'waypoints': waypoints,
      };
}
