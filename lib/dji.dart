import 'dart:async';
import 'messages.dart';
import 'flight.dart';

class Dji {
  static DjiHostApi? _apiInstance;

  static DjiHostApi? get _api {
    if (_apiInstance == null) {
      _apiInstance = DjiHostApi();
    }
    return _apiInstance;
  }

  static Future<String?> get platformVersion async {
    Version? version = await _api?.getPlatformVersion();
    return version?.string;
  }

  static Future<int?> get batteryLevel async {
    Battery? battery = await _api?.getBatteryLevel();
    return battery?.level;
  }

  static Future<void> get registerApp async {
    await _api?.registerApp();
  }

  static Future<void> get connectDrone async {
    await _api?.connectDrone();
  }

  static Future<void> get disconnectDrone async {
    await _api?.disconnectDrone();
  }

  static Future<void> get delegateDrone async {
    await _api?.delegateDrone();
  }

  static Future<void> get takeOff async {
    await _api?.takeOff();
  }

  static Future<void> get land async {
    await _api?.land();
  }

  static Future<void> get timeline async {
    await _api?.timeline();
  }

  static Future<void> get start async {
    // List<FlightElement> timeline = [];

    // final FlightElement takeOffElement =
    //     FlightElement(type: FlightElementType.takeOff);
    // final FlightElement landElement =
    //     FlightElement(type: FlightElementType.land);

    // timeline.add(takeOffElement);
    // timeline.add(landElement);

    // Flight flight = Flight(timeline);

    Flight flight = Flight.fromJson({
      'timeline': [
        {
          'type': 'takeOff',
        },
        {
          'type': 'land',
        },
        // {
        //   'type': 'waypointMission',
        //   'waypoints': [
        //     {
        //       'longitude': 1.0,
        //       'latidue': 1.0,
        //       'altitude': 1.0,
        //     },
        //     {
        //       'longitude': 2.0,
        //       'latidue': 2.0,
        //       'altitude': 2.0,
        //     },
        //   ],
        // },
      ],
    });

    await _api?.start(flight);
  }
}
