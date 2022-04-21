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
      latitude: 32.2182526,
      longitude: 34.86474411,
      altitude: 0,
    );

    Flight flight = Flight.fromJson({
      'timeline': [
        {
          'type': 'waypointMission',
          'pointOfInterest': {
            'latitude': ((droneHomeLocation.latitude + (100 * 0.00000899322)) *
                        100000000)
                    .round() /
                100000000,
            'longitude': ((droneHomeLocation.longitude + (0 * 0.00000899322)) *
                        100000000)
                    .round() /
                100000000,
            'altitude': droneHomeLocation.altitude,
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
                'distanceFromPointOfInterest': 100,
                'headingRelativeToPointOfInterest': -45,
                'destinationAltitude': 2,
              },
              'cornerRadiusInMeters': 2,
              'turnMode': 'counterClockwise',
            },
            {
              'vector': {
                'distanceFromPointOfInterest': 100,
                'headingRelativeToPointOfInterest': -135,
                'destinationAltitude': 2,
              },
              'cornerRadiusInMeters': 2,
              'turnMode': 'counterClockwise',
            },
            {
              'vector': {
                'distanceFromPointOfInterest': 100,
                'headingRelativeToPointOfInterest': -225,
                'destinationAltitude': 6,
              },
              'cornerRadiusInMeters': 2,
              'turnMode': 'counterClockwise',
            },
            {
              'vector': {
                'distanceFromPointOfInterest': 100,
                'headingRelativeToPointOfInterest': -315,
                'destinationAltitude': 4,
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

    expect(element.waypoints[0].location?.latitude, equals(32.218516));
    expect(element.waypoints[0].location?.longitude, equals(34.86538003));
    // expect(element.waypoints[0].gimbalPitch, equals(-45));
    print(
        'Waypoint 1: ${element.waypoints[0].location?.latitude}, ${element.waypoints[0].location?.longitude}');

    expect(element.waypoints[1].location?.latitude, equals(32.21978784));
    expect(element.waypoints[1].location?.longitude, equals(34.86538003));
    // expect(element.waypoints[1].gimbalPitch, equals(-45));
    print(
        'Waypoint 2: ${element.waypoints[1].location?.latitude}, ${element.waypoints[1].location?.longitude}');

    expect(element.waypoints[2].location?.latitude, equals(32.21978784));
    expect(element.waypoints[2].location?.longitude, equals(34.86410819));
    // expect(element.waypoints[2].gimbalPitch, equals(-45));
    print(
        'Waypoint 3: ${element.waypoints[2].location?.latitude}, ${element.waypoints[2].location?.longitude}');

    expect(element.waypoints[3].location?.latitude, equals(32.21851600));
    expect(element.waypoints[3].location?.longitude, equals(34.86410819));
    // expect(element.waypoints[3].gimbalPitch, equals(-45));
    print(
        'Waypoint 4: ${element.waypoints[3].location?.latitude}, ${element.waypoints[3].location?.longitude}');
  });
}
