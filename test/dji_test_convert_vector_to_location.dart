// Run this test using:
// flutter test test/dji_test_convert_vector_to_location.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dji/flight.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Converting a specific vector object to location coordinates', () async {
    // Example Home 1 (Benei Zion): 32.2182526, 34.86474411
    // Example Home 2 (Even Yehuda): 32.26215, 34.88217
    final droneHomeLocation = FlightLocation(
      latitude: 32.2182526,
      longitude: 34.86474411,
      altitude: 0,
    );

    // Setting a point-of-intereset to a few meters away from the Drone's home location.
    // And setting the precision to 8 decimals (~1.1mm accuracy, which is the GPS limit).
    final pointOfInterest = FlightLocation(
      latitude:
          ((droneHomeLocation.latitude + (100 * 0.00000899322)) * 100000000)
                  .round() /
              100000000,
      longitude:
          ((droneHomeLocation.longitude + (0 * 0.00000899322)) * 100000000)
                  .round() /
              100000000,
      altitude: droneHomeLocation.altitude,
    );

    final vector = FlightVector(
      distanceFromPointOfInterest: 100,
      headingRelativeToPointOfInterest: 45,
      destinationAltitude: 2,
    );

    final computedLocation = CoordinatesConvertion.vectorToLocation(
      droneLocation: droneHomeLocation,
      pointOfInterest: pointOfInterest,
      vector: vector,
    );

    print('Drone Home Location:');
    print('${droneHomeLocation.latitude}, ${droneHomeLocation.longitude}');

    print('Point of Intereset:');
    print('${pointOfInterest.latitude}, ${pointOfInterest.longitude}');

    print('Computed (Waypoint) Location:');
    print('${computedLocation!.latitude}, ${computedLocation.longitude}');

    expect(computedLocation.latitude, equals(32.218516));
    expect(computedLocation.longitude, equals(34.86410819));
  });
}
