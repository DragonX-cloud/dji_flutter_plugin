// Run this test using:
// flutter test test/dji_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dji/flight.dart';

void main() {
  // const MethodChannel channel = MethodChannel('dji');

  TestWidgetsFlutterBinding.ensureInitialized();

  // setUp(() {
  //   channel.setMockMethodCallHandler((MethodCall methodCall) async {
  //     return '42';
  //   });
  // });

  // tearDown(() {
  //   channel.setMockMethodCallHandler(null);
  // });

  // test('getPlatformVersion', () async {
  //   expect(await Dji.platformVersion, '42');
  // });

  test(
      'Converting Waypoint Mission Vector Objects to Location Objects and compute Gimbal Pitch',
      () {
    final droneHomeLocation = FlightLocation(
      latitude: 32.2617757,
      longitude: 34.8821537,
      altitude: 0,
    );

    Flight flight = Flight.fromJson({
      'timeline': [
        {
          'type': 'waypointMission',
          'pointOfInterest': {
            // 'latitude': ((droneHomeLocation.latitude + (100 * 0.00000899322)) *
            //             100000000)
            //         .round() /
            //     100000000,
            // 'longitude': ((droneHomeLocation.longitude + (0 * 0.00000899322)) *
            //             100000000)
            //         .round() /
            //     100000000,
            // 'altitude': droneHomeLocation.altitude,
            'latitude': 32.2614854,
            'longitude': 34.8819790,
            'altitude': 0,
          },
          'maxFlightSpeed': 15.0,
          'autoFlightSpeed': 10.0,
          'finishedAction': 'noAction',
          'headingMode': 'towardPointOfInterest',
          'flightPathMode': 'curved',
          'rotateGimbalPitch': true,
          'exitMissionOnRCSignalLost': true,
          'waypoints': [
            {
              'vector': {
                'distanceFromPointOfInterest': 20,
                'headingRelativeToPointOfInterest': 45,
                'destinationAltitude': 10,
              },
              'cornerRadiusInMeters': 5,
              'turnMode': 'counterClockwise',
            },
            {
              'vector': {
                'distanceFromPointOfInterest': 20,
                'headingRelativeToPointOfInterest': -45,
                'destinationAltitude': 10,
              },
              'cornerRadiusInMeters': 5,
              'turnMode': 'counterClockwise',
            },
            {
              'vector': {
                'distanceFromPointOfInterest': 20,
                'headingRelativeToPointOfInterest': -135,
                'destinationAltitude': 20,
              },
              'cornerRadiusInMeters': 5,
              'turnMode': 'counterClockwise',
            },
            {
              'vector': {
                'distanceFromPointOfInterest': 20,
                'headingRelativeToPointOfInterest': -225,
                'destinationAltitude': 10,
              },
              'cornerRadiusInMeters': 5,
              'turnMode': 'counterClockwise',
            },
          ],
        },
      ],
    });

    // Converting any vector definitions in waypoint-mission to locations
    for (dynamic element in flight.timeline) {
      if (element.type == FlightElementType.waypointMission) {
        CoordinatesConvertion
            .convertWaypointMissionVectorsToLocationsWithGimbalPitch(
                flightElementWaypointMission: element,
                droneHomeLocation: droneHomeLocation);
      }
    }

    final FlightElementWaypointMission element =
        flight.timeline[0] as FlightElementWaypointMission;

    expect(element.waypoints[0].location?.latitude, equals(32.26152879),
        reason: 'latitude');
    expect(element.waypoints[0].location?.longitude, equals(34.88215355),
        reason: 'longitude');
    // expect(element.waypoints[0].gimbalPitch, equals(-45));
    print(
        'Waypoint 1: ${element.waypoints[0].location?.latitude}, ${element.waypoints[0].location?.longitude}');

    expect(element.waypoints[1].location?.latitude, equals(32.26165995),
        reason: 'latitude');
    expect(element.waypoints[1].location?.longitude, equals(34.88193561),
        reason: 'longitude');
    // expect(element.waypoints[1].gimbalPitch, equals(-45));
    print(
        'Waypoint 2: ${element.waypoints[1].location?.latitude}, ${element.waypoints[1].location?.longitude}');

    expect(element.waypoints[2].location?.latitude, equals(32.26144201),
        reason: 'latitude');
    expect(element.waypoints[2].location?.longitude, equals(34.88180445),
        reason: 'longitude');
    // expect(element.waypoints[2].gimbalPitch, equals(-45));
    print(
        'Waypoint 3: ${element.waypoints[2].location?.latitude}, ${element.waypoints[2].location?.longitude}');

    expect(element.waypoints[3].location?.latitude, equals(32.26131085),
        reason: 'latitude');
    expect(element.waypoints[3].location?.longitude, equals(34.88202239),
        reason: 'longitude');
    // expect(element.waypoints[3].gimbalPitch, equals(-45));
    print(
        'Waypoint 4: ${element.waypoints[3].location?.latitude}, ${element.waypoints[3].location?.longitude}');
  });

  test(
      'Checking waypoint when Drone is at 0,0 and Point of Interest is 10m to the south, and the drone destination is 90 degrees to the east.',
      () {
    final droneHomeLocation = FlightLocation(
      latitude: 0,
      longitude: 0,
      altitude: 0,
    );

    Flight flight = Flight.fromJson({
      'timeline': [
        {
          'type': 'waypointMission',
          'pointOfInterest': {
            'latitude': -0.000008993 * 10,
            'longitude': 0,
            'altitude': 0,
          },
          'maxFlightSpeed': 15.0,
          'autoFlightSpeed': 10.0,
          'finishedAction': 'noAction',
          'headingMode': 'towardPointOfInterest',
          'flightPathMode': 'curved',
          'rotateGimbalPitch': true,
          'exitMissionOnRCSignalLost': true,
          'waypoints': [
            {
              'vector': {
                'distanceFromPointOfInterest': 10,
                'headingRelativeToPointOfInterest': 90,
                'destinationAltitude': 2,
              },
              'cornerRadiusInMeters': 2,
              'turnMode': 'counterClockwise',
            },
          ],
        },
      ],
    });

    // Converting any vector definitions in waypoint-mission to locations
    for (dynamic element in flight.timeline) {
      if (element.type == FlightElementType.waypointMission) {
        CoordinatesConvertion
            .convertWaypointMissionVectorsToLocationsWithGimbalPitch(
                flightElementWaypointMission: element,
                droneHomeLocation: droneHomeLocation);
      }
    }

    final FlightElementWaypointMission element =
        flight.timeline[0] as FlightElementWaypointMission;

    print(
        'Waypoint 1: ${element.waypoints[0].location?.latitude}, ${element.waypoints[0].location?.longitude}');

    expect(element.waypoints[0].location?.latitude, equals(-0.000008993 * 10),
        reason: 'latitude');
    expect(element.waypoints[0].location?.longitude, equals(0.000008993 * 10),
        reason: 'longitude');
  });

  test(
      'Checking waypoint when Drone is at 0,0 and Point of Interest is 10m to the north, and the drone destination is 90 degrees to the west.',
      () {
    final droneHomeLocation = FlightLocation(
      latitude: 0,
      longitude: 0,
      altitude: 0,
    );

    Flight flight = Flight.fromJson({
      'timeline': [
        {
          'type': 'waypointMission',
          'pointOfInterest': {
            'latitude': 0.000008993 * 10,
            'longitude': 0,
            'altitude': 0,
          },
          'maxFlightSpeed': 15.0,
          'autoFlightSpeed': 10.0,
          'finishedAction': 'noAction',
          'headingMode': 'towardPointOfInterest',
          'flightPathMode': 'curved',
          'rotateGimbalPitch': true,
          'exitMissionOnRCSignalLost': true,
          'waypoints': [
            {
              'vector': {
                'distanceFromPointOfInterest': 10,
                'headingRelativeToPointOfInterest': 90,
                'destinationAltitude': 2,
              },
              'cornerRadiusInMeters': 2,
              'turnMode': 'counterClockwise',
            },
          ],
        },
      ],
    });

    // Converting any vector definitions in waypoint-mission to locations
    for (dynamic element in flight.timeline) {
      if (element.type == FlightElementType.waypointMission) {
        CoordinatesConvertion
            .convertWaypointMissionVectorsToLocationsWithGimbalPitch(
                flightElementWaypointMission: element,
                droneHomeLocation: droneHomeLocation);
      }
    }

    final FlightElementWaypointMission element =
        flight.timeline[0] as FlightElementWaypointMission;

    print(
        'Waypoint 1: ${element.waypoints[0].location?.latitude}, ${element.waypoints[0].location?.longitude}');

    expect(element.waypoints[0].location?.latitude, equals(0.000008993 * 10),
        reason: 'latitude');
    expect(element.waypoints[0].location?.longitude, equals(-0.000008993 * 10),
        reason: 'longitude');
  });

  test(
      'Checking waypoint when Drone is at 0,0 and Point of Interest is 10m to the north and 10m to the east, and the drone destination is 45 degrees to the west.',
      () {
    final droneHomeLocation = FlightLocation(
      latitude: 0,
      longitude: 0,
      altitude: 0,
    );

    Flight flight = Flight.fromJson({
      'timeline': [
        {
          'type': 'waypointMission',
          'pointOfInterest': {
            'latitude': 0.000008993 * 10,
            'longitude': 0.000008993 * 10,
            'altitude': 0,
          },
          'maxFlightSpeed': 15.0,
          'autoFlightSpeed': 10.0,
          'finishedAction': 'noAction',
          'headingMode': 'towardPointOfInterest',
          'flightPathMode': 'curved',
          'rotateGimbalPitch': true,
          'exitMissionOnRCSignalLost': true,
          'waypoints': [
            {
              'vector': {
                'distanceFromPointOfInterest': 10,
                'headingRelativeToPointOfInterest': 45,
                'destinationAltitude': 2,
              },
              'cornerRadiusInMeters': 2,
              'turnMode': 'counterClockwise',
            },
          ],
        },
      ],
    });

    // Converting any vector definitions in waypoint-mission to locations
    for (dynamic element in flight.timeline) {
      if (element.type == FlightElementType.waypointMission) {
        CoordinatesConvertion
            .convertWaypointMissionVectorsToLocationsWithGimbalPitch(
                flightElementWaypointMission: element,
                droneHomeLocation: droneHomeLocation);
      }
    }

    final FlightElementWaypointMission element =
        flight.timeline[0] as FlightElementWaypointMission;

    print(
        'Waypoint 1: ${element.waypoints[0].location?.latitude}, ${element.waypoints[0].location?.longitude}');

    expect(element.waypoints[0].location?.latitude, equals(0.000008993 * 10),
        reason: 'latitude');
    expect(element.waypoints[0].location?.longitude, equals(0.0),
        reason: 'longitude');
  });

  test(
      'Checking waypoint when Drone is at 0,0 and Point of Interest is 10m to the north and 10m to the west, and the drone destination is 0 degrees towards the drone home.',
      () {
    final droneHomeLocation = FlightLocation(
      latitude: 0,
      longitude: 0,
      altitude: 0,
    );

    Flight flight = Flight.fromJson({
      'timeline': [
        {
          'type': 'waypointMission',
          'pointOfInterest': {
            'latitude': 0.000008993 * 10,
            'longitude': -0.000008993 * 10,
            'altitude': 0,
          },
          'maxFlightSpeed': 15.0,
          'autoFlightSpeed': 10.0,
          'finishedAction': 'noAction',
          'headingMode': 'towardPointOfInterest',
          'flightPathMode': 'curved',
          'rotateGimbalPitch': true,
          'exitMissionOnRCSignalLost': true,
          'waypoints': [
            {
              'vector': {
                'distanceFromPointOfInterest': 14.142135,
                'headingRelativeToPointOfInterest': 0,
                'destinationAltitude': 0,
              },
              'cornerRadiusInMeters': 2,
              'turnMode': 'counterClockwise',
            },
          ],
        },
      ],
    });

    // Converting any vector definitions in waypoint-mission to locations
    for (dynamic element in flight.timeline) {
      if (element.type == FlightElementType.waypointMission) {
        CoordinatesConvertion
            .convertWaypointMissionVectorsToLocationsWithGimbalPitch(
                flightElementWaypointMission: element,
                droneHomeLocation: droneHomeLocation);
      }
    }

    final FlightElementWaypointMission element =
        flight.timeline[0] as FlightElementWaypointMission;

    print(
        'Waypoint 1: ${element.waypoints[0].location?.latitude}, ${element.waypoints[0].location?.longitude}');

    expect(element.waypoints[0].location?.latitude, equals(0.0),
        reason: 'latitude');
    expect(element.waypoints[0].location?.longitude, equals(0.0),
        reason: 'longitude');
  });
}
