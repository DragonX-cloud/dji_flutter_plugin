/*
* Note:
* Did not want to use any packages, for minimal dependencies, and therefore instead of using json_serialization package or string_to_enum, manually implemented the convertion from Enum to String, inspired by the enum_to_string package.
* Enum to String: https://pub.dev/packages/enum_to_string
* JSON Serializable: https://pub.dev/packages/json_serializable
*
* Dart playground of the code below:
* https://dartpad.dev/624647f30ece6b443e8b4a5708f5a87b
*/

class EnumConvertion {
  static bool _isEnumItem(enumItem) {
    final splitEnum = enumItem.toString().split('.');
    return splitEnum.length > 1 &&
        splitEnum[0] == enumItem.runtimeType.toString();
  }

  static String convertToString(dynamic enumItem) {
    assert(enumItem != null);
    assert(_isEnumItem(enumItem),
        '$enumItem of type ${enumItem.runtimeType.toString()} is not an enum item');
    final _tmp = enumItem.toString().split('.')[1];
    return _tmp;
  }

  static T? convertFromString<T>(List<T> enumValues, String value) {
    try {
      return enumValues.singleWhere((enumItem) =>
          convertToString(enumItem).toLowerCase() == value.toLowerCase());
    } on StateError catch (_) {
      return null;
    }
  }
}

// Flight (Timeline)
class Flight {
  final List<FlightElement> timeline;

  Flight(this.timeline);

  Flight.fromJson(Map<String, dynamic> json)
      : this.timeline = (json['timeline'] as List).map((i) {
          if (i['type'] ==
              EnumConvertion.convertToString(
                  FlightElementType.waypointMission)) {
            return FlightElementWaypointMission.fromJson(i);
          } else {
            return FlightElement.fromJson(i);
          }
        }).toList();

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> timeline =
        this.timeline.map((i) => i.toJson()).toList();

    return {
      'timeline': timeline,
    };
  }
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
  final FlightElementType? type;

  FlightElement({required this.type});

  FlightElement.fromJson(Map<String, dynamic> json)
      : this.type = EnumConvertion.convertFromString(
            FlightElementType.values, json['type']);

  Map<String, dynamic> toJson() => {
        'type': EnumConvertion.convertToString(type),
      };
}

// Location (3D Coordinates = 2D Coordinates and Altitude)
// In the DJI SDK, 2D Coordinates (Longitude, Latitude) are defined by Class CLLocationCoordinate2D
// While 3D Coordinates (Longitude, Latitude, Altitude) are defined by Class CLLocation
class FlightLocation {
  final double longitude;
  final double latitude;
  final double altitude;

  FlightLocation({
    required this.longitude,
    required this.latitude,
    required this.altitude,
  });

  FlightLocation.fromJson(Map<String, dynamic> json)
      : this.longitude = double.parse(json['longitude'].toString()),
        this.latitude = double.parse(json['latitude'].toString()),
        this.altitude = double.parse(json['altitude'].toString());

  Map<String, dynamic> toJson() => {
        'longitude': longitude,
        'latitude': latitude,
        'altitude': altitude,
      };
}

// Waypoint

enum FlightWaypointTurnMode {
  clockwise,
  counterClockwise,
}

class FlightWaypoint {
  final FlightLocation? location;
  final int?
      heading; // -180..180 degrees; Relevant only if flightWaypointMissionHeadingMode is FlightWaypointMissionHeadingMode.usingWaypointHeading;
  final double? cornerRadiusInMeters;
  final FlightWaypointTurnMode? turnMode;
  final double?
      gimbalPitch; // The final position of the gimbal, when the drone reaches the endpoint; Relevant only if rotateGimbalPitch is TRUE;

  FlightWaypoint({
    required this.location,
    this.heading = 0,
    this.cornerRadiusInMeters = 2,
    this.turnMode = FlightWaypointTurnMode.clockwise,
    this.gimbalPitch = 0,
  });

  FlightWaypoint.fromJson(Map<String, dynamic> json)
      : this.location = json['location'].fromJson(),
        this.heading = json['heading'] != null
            ? int.parse(json['heading'].toString())
            : null,
        this.cornerRadiusInMeters = json['cornerRadiusInMeters'] != null
            ? double.parse(json['cornerRadiusInMeters'].toString())
            : null,
        this.turnMode = EnumConvertion.convertFromString(
            FlightWaypointTurnMode.values, json['turnMode']),
        this.gimbalPitch = json['gimbalPitch'] != null
            ? double.parse(json['gimbalPitch'].toString())
            : null;

  Map<String, dynamic> toJson() => {
        'location': location?.toJson(),
        'heading': heading,
        'cornerRadiusInMeters': cornerRadiusInMeters,
        'turnMode': EnumConvertion.convertToString(turnMode),
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
  final FlightLocation? pointOfInterest;
  final double? maxFlightSpeed;
  final double? autoFlightSpeed;
  final FlightWaypointMissionFinishedAction? finishedAction;
  final FlightWaypointMissionHeadingMode? headingMode;
  final FlightWaypointMissionPathMode? flightPathMode;
  final bool? rotateGimbalPitch;
  final bool? exitMissionOnRCSignalLost;

  final List<FlightWaypoint> waypoints;

  FlightElementWaypointMission({
    this.pointOfInterest,
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
      : this.pointOfInterest = json['pointOfInterest'].fromJson(),
        this.maxFlightSpeed = json['maxFlightSpeed'] != null
            ? double.parse(json['maxFlightSpeed'].toString())
            : null,
        this.autoFlightSpeed = json['autoFlightSpeed'] != null
            ? double.parse(json['autoFlightSpeed'].toString())
            : null,
        this.finishedAction = EnumConvertion.convertFromString(
            FlightWaypointMissionFinishedAction.values, json['finishedAction']),
        this.headingMode = EnumConvertion.convertFromString(
            FlightWaypointMissionHeadingMode.values, json['headingMode']),
        this.flightPathMode = EnumConvertion.convertFromString(
            FlightWaypointMissionPathMode.values, json['flightPathMode']),
        this.rotateGimbalPitch =
            json['rotateGimbalPitch'] != null ? true : false,
        this.exitMissionOnRCSignalLost =
            json['exitMissionOnRCSignalLost'] != null ? true : false,
        this.waypoints = (json['waypoints'] as List)
            .map((i) => FlightWaypoint.fromJson(i))
            .toList(),
        super(type: FlightElementType.waypointMission);

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> waypoints =
        this.waypoints.map((i) => i.toJson()).toList();

    return {
      'type': EnumConvertion.convertToString(type),
      'pointOfInterest': pointOfInterest?.toJson(),
      'maxFlightSpeed': maxFlightSpeed,
      'autoFlightSpeed': autoFlightSpeed,
      'finishedAction': EnumConvertion.convertToString(finishedAction),
      'headingMode': EnumConvertion.convertToString(headingMode),
      'flightPathMode': EnumConvertion.convertToString(flightPathMode),
      'rotateGimbalPitch': rotateGimbalPitch,
      'exitMissionOnRCSignalLost': exitMissionOnRCSignalLost,
      'waypoints': waypoints,
    };
  }
}
