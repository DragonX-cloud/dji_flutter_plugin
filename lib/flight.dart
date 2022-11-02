import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

const String kLogKindDjiFlutterPlugin = 'dji.flutter';

/// Enum Convertion Methods
///
/// Did not want to use any packages, for minimal dependencies, and therefore instead of using json_serialization package or string_to_enum, manually implemented the convertion from Enum to String, inspired by the enum_to_string package.
///
/// Enum to String: https://pub.dev/packages/enum_to_string
///
/// JSON Serializable: https://pub.dev/packages/json_serializable
///
/// Dart playground of the code below: https://dartpad.dev/624647f30ece6b443e8b4a5708f5a87b
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

/// Coordinates Convertion Methods.
///
/// Decimal Degrees: http://wiki.gis.com/wiki/index.php/Decimal_degrees
///
/// Coordinates Convertor: https://www.pgc.umn.edu/apps/convert/
///
/// ```
/// 1 degree = 111,319.9m
/// 0.00000898311 degrees = 1m
/// ```
///
/// Example:
/// ```
///          Destination (x3, y3)
///                 /
///     Drone      /
///    (x2,y2)    /
///       |      /
///       |     / a
///       |    /
///       |   /
///       |  /
///       | /
///       |/
/// pointOfInterest (x1, y1)
/// ```
class CoordinatesConvertion {
  static const meterToDecimalDegree = 0.00000899322; //0.00000898311;

  static FlightLocation? vectorToLocation(
      {required FlightLocation droneLocation,
      required FlightLocation pointOfInterest,
      required FlightVector vector}) {
    if (droneLocation.latitude == pointOfInterest.latitude &&
        droneLocation.longitude == pointOfInterest.longitude) {
      developer.log(
        'vectorToLocation - Waypoint Mission Point of Interest cannot be identical to the drone (home) location',
        name: kLogKindDjiFlutterPlugin,
      );
      return null;
    }

    final double alpha = (atan(
            (droneLocation.longitude - pointOfInterest.longitude) /
                (droneLocation.latitude - pointOfInterest.latitude)) *
        180 /
        pi);

    final double azimuth;
    if (droneLocation.latitude - pointOfInterest.latitude < 0) {
      // Drone is south to the Point of Interest
      // We need to add 180 to the azimuth (to compensate for the negative angle)
      azimuth = (alpha + 180) % 360;
    } else {
      azimuth = alpha % 360;
    }

    final double azimuthToDestination =
        (azimuth + vector.headingRelativeToPointOfInterest) % 360;

    // Latitude = North/South
    double computedDestinationLatitude = pointOfInterest.latitude +
        (vector.distanceFromPointOfInterest *
            sin((90 - azimuthToDestination) * pi / 180) *
            meterToDecimalDegree);
    // Setting the Latitude precision to 8 decimals (~1.1mm accuracy, which is the GPS limit).
    computedDestinationLatitude = computedDestinationLatitude * 100000000;
    final double destinationLatitude =
        computedDestinationLatitude.round() / 100000000;

    // Longitude = East/West
    double computedDestinationLongitude = pointOfInterest.longitude +
        (vector.distanceFromPointOfInterest *
            cos((90 - azimuthToDestination) * pi / 180) *
            meterToDecimalDegree);
    // Setting the Latitude precision to 8 decimals (~1.1mm accuracy, which is the GPS limit).
    computedDestinationLongitude = computedDestinationLongitude * 100000000;
    final double destinationLongitude =
        computedDestinationLongitude.round() / 100000000;

    developer.log(
      'vectorToLocation - computed coordinates:',
      name: kLogKindDjiFlutterPlugin,
    );
    developer.log(
      'Latitude: $destinationLatitude',
      name: kLogKindDjiFlutterPlugin,
    );
    developer.log(
      'Longitude: $destinationLongitude',
      name: kLogKindDjiFlutterPlugin,
    );
    developer.log(
      'Altitude: ${vector.destinationAltitude}',
      name: kLogKindDjiFlutterPlugin,
    );

    return FlightLocation(
        latitude: destinationLatitude,
        longitude: destinationLongitude,
        altitude: vector.destinationAltitude);
  }

  static double computeGimbalAngle(
      FlightLocation pointOfInterest, FlightLocation droneLocation) {
    /// Calculating the distance between the drone and the point-of-interest (inclduing height)
    final double latitudeDeltaInMeters =
        (droneLocation.latitude / meterToDecimalDegree) -
            (pointOfInterest.latitude / meterToDecimalDegree);
    final double longitudeDeltaInMeters =
        (droneLocation.longitude / meterToDecimalDegree) -
            (pointOfInterest.longitude / meterToDecimalDegree);
    final double altitudeDeltaInMeters =
        droneLocation.altitude - pointOfInterest.altitude;

    /// The ground distance (in meters) between the drone and the point-of-interest (without altitude)
    final double groundDistanceInMeters =
        sqrt(pow(longitudeDeltaInMeters, 2) + pow(latitudeDeltaInMeters, 2));

    final double gimbalAngleInDegrees =
        atan(altitudeDeltaInMeters / groundDistanceInMeters) * 180 / pi;

    /// We return the gimbal angle as a "minus" to match the DJI SDK gimbalPitch definition.
    return (gimbalAngleInDegrees.abs() * -1).roundToDouble();
  }

  static convertWaypointMissionVectorsToLocationsWithGimbalPitch(
      {required FlightElementWaypointMission flightElementWaypointMission,
      required FlightLocation droneHomeLocation}) {
    if (flightElementWaypointMission.pointOfInterest == null) {
      developer.log(
        'convertWaypointMissionVectorsToLocations - Waypoint Mission Point of Interest does not exist',
        name: kLogKindDjiFlutterPlugin,
      );
    }

    int unableToComputeLocationBasedOnVector = -1;
    int count = 0;
    for (FlightWaypoint waypoint in flightElementWaypointMission.waypoints) {
      // Compute Location per Vector definition
      if (waypoint.vector != null && waypoint.location == null) {
        waypoint.location = CoordinatesConvertion.vectorToLocation(
            droneLocation: droneHomeLocation,
            pointOfInterest: flightElementWaypointMission.pointOfInterest!,
            vector: waypoint.vector!);

        /// If we weren't able to compute the location - we mark the failure and the parent method will return null
        if (waypoint.location == null) {
          unableToComputeLocationBasedOnVector = count;
        }
      } else {
        /// Location already exists - Keeping the existing waypoint
      }

      /// Compute Gimbal Angle, but only if it doesn't exist
      if (waypoint.gimbalPitch == null && waypoint.location != null) {
        waypoint.gimbalPitch = CoordinatesConvertion.computeGimbalAngle(
            flightElementWaypointMission.pointOfInterest!, waypoint.location!);
      }

      count++;
    }

    if (unableToComputeLocationBasedOnVector > -1) {
      developer.log(
        'convertWaypointMissionVectorsToLocations - Unable to compute Waypoint Location based on Waypoint Vector #$unableToComputeLocationBasedOnVector inputs',
        name: kLogKindDjiFlutterPlugin,
      );
    }

    developer.log(
      'convertWaypointMissionVectorsToLocations - updated waypoints: ${jsonEncode(flightElementWaypointMission.waypoints)}',
      name: kLogKindDjiFlutterPlugin,
    );
  }
}

/// Flight (Timeline).
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

/// Flight Element Types.

enum FlightElementType {
  takeOff,
  land,
  // goto,
  // home,
  // hotpoint,
  waypointMission,
  singleShootPhoto,
  startRecordVideo,
  stopRecordVideo,
}

/// Flight Element.

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

/// Flight Location.
///
/// Location (3D Coordinates = 2D Coordinates and Altitude)
///
/// In the DJI SDK, 2D Coordinates (Longitude, Latitude) are defined by Class CLLocationCoordinate2D
///
/// While 3D Coordinates (Longitude, Latitude, Altitude) are defined by Class CLLocation
class FlightLocation {
  final double latitude;
  final double longitude;
  final double altitude;

  FlightLocation({
    required this.latitude,
    required this.longitude,
    required this.altitude,
  });

  FlightLocation.fromJson(Map<String, dynamic> json)
      : this.latitude = double.parse(json['latitude'].toString()),
        this.longitude = double.parse(json['longitude'].toString()),
        this.altitude = double.parse(json['altitude'].toString());

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
      };
}

/// Flight Vector.
///
/// The Flight Vector defines the distance and heading towards the destination in relation to the point-of-interest.
///
/// Including the altitude at the destination.
///
/// The destination is the waypoint.
///
/// The heading is the angle between the point-of-interest (of the Waypoint Mission) and the destination waypoint.
class FlightVector {
  final double distanceFromPointOfInterest; // Distance in Meters
  final double headingRelativeToPointOfInterest; // Angle in Degrees
  final double destinationAltitude; // Altitude in Meters

  FlightVector(
      {required this.distanceFromPointOfInterest,
      required this.headingRelativeToPointOfInterest,
      required this.destinationAltitude});

  FlightVector.fromJson(Map<String, dynamic> json)
      : this.distanceFromPointOfInterest =
            double.parse(json['distanceFromPointOfInterest'].toString()),
        this.headingRelativeToPointOfInterest =
            double.parse(json['headingRelativeToPointOfInterest'].toString()),
        this.destinationAltitude =
            double.parse(json['destinationAltitude'].toString());

  Map<String, dynamic> toJson() => {
        'distanceFromPointOfInterest': distanceFromPointOfInterest,
        'headingRelativeToPointOfInterest': headingRelativeToPointOfInterest,
        'destinationAltitude': destinationAltitude,
      };
}

/// Waypoint Turn Modes.

enum FlightWaypointTurnMode {
  clockwise,
  counterClockwise,
}

/// Waypoint.
class FlightWaypoint {
  FlightLocation?
      location; // location is mutatable because if we have a vector instead of location - we convert the vector to a location before using the waypoint.
  final FlightVector? vector;
  final int?
      heading; // -180..180 degrees; Relevant only if flightWaypointMissionHeadingMode is FlightWaypointMissionHeadingMode.usingWaypointHeading;
  final double? cornerRadiusInMeters;
  final FlightWaypointTurnMode? turnMode;
  double?
      gimbalPitch; // The final position of the gimbal, when the drone reaches the endpoint; Relevant only if rotateGimbalPitch is TRUE;

  FlightWaypoint({
    required this.location,
    required this.vector,
    this.heading = 0,
    this.cornerRadiusInMeters = 2,
    this.turnMode = FlightWaypointTurnMode.clockwise,
    this.gimbalPitch,
  });

  FlightWaypoint.fromJson(Map<String, dynamic> json)
      : this.location = json['location'] != null
            ? FlightLocation.fromJson(json['location'])
            : null,
        this.vector = json['vector'] != null
            ? FlightVector.fromJson(json['vector'])
            : null,
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
        'vector': vector?.toJson(),
        'heading': heading,
        'cornerRadiusInMeters': cornerRadiusInMeters,
        'turnMode': EnumConvertion.convertToString(turnMode),
        'gimbalPitch': gimbalPitch,
      };
}

/// Waypoint Mission Heading Modes.

enum FlightWaypointMissionHeadingMode {
  auto,
  towardPointOfInterest,
  usingWaypointHeading,
}

/// Waypoint Mission Path Modes.

enum FlightWaypointMissionPathMode {
  normal,
  curved,
}

/// Waypoint Mission Finish Actions options.

enum FlightWaypointMissionFinishedAction {
  noAction,
  autoLand,
  continueUntilStop,
  goFirstWaypoint,
  goHome,
}

/// Waypoint Mission.

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
      : this.pointOfInterest = json['pointOfInterest'] != null
            ? FlightLocation.fromJson(json['pointOfInterest'])
            : null,
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
