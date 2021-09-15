import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dji/flight.dart';
import 'package:dji/dji.dart';

void main() {
  const MethodChannel channel = MethodChannel('dji');

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

  test('Convertng Waypoint Mission Vector Objects to Location Objects', () {
    Flight flight = Flight.fromJson({
      'timeline': [
        {
          'type': 'waypointMission',
          'pointOfInterest': {
            'longitude': 0.0,
            'latitude': 0.0,
            'altitude': 0.0,
          },
          'maxFlightSpeed': 25.0,
          'autoFlightSpeed': 10.0,
          'finishedAction': 'noAction',
          'headingMode': 'towardPointOfInterest',
          'flightPathMode': 'curved',
          'rotateGimbalPitch': true,
          'exitMissionOnRCSignalLost': true,
          'waypoints': [
            {
              'vector': {
                'distanceFromPointOfInterest': 1,
                'headingRelativeToPointOfInterest': 45,
                'destinationAltitude': 1,
              },
              'cornerRadiusInMeters': 5,
              'turnMode': 'clockwise',
              'gimbalPitch': 0,
            },
            {
              'vector': {
                'distanceFromPointOfInterest': 1,
                'headingRelativeToPointOfInterest': -45,
                'destinationAltitude': 2,
              },
              'cornerRadiusInMeters': 5,
              'turnMode': 'clockwise',
              'gimbalPitch': 0,
            },
          ],
        },
      ],
    });

    final droneHomeLocation =
        FlightLocation(latitude: 1, longitude: 0, altitude: 0);

    // Converting any vector definitions in waypoint-mission to locations
    for (dynamic element in flight.timeline) {
      if (element.type == FlightElementType.waypointMission) {
        coordinatesConvertion.convertWaypointMissionVectorsToLocations(
            flightElementWaypointMission: element,
            droneHomeLocation: droneHomeLocation);
      }
    }

    final FlightElementWaypointMission element =
        flight.timeline[0] as FlightElementWaypointMission;
    expect(element.waypoints[0].location?.latitude,
        equals(0.000006352017997144686));
    expect(element.waypoints[0].location?.longitude,
        equals(0.000006352017997144687));
  });
}
