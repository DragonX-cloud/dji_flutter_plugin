import 'dart:async';
import 'dart:convert';
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

  /// Gets the platform version.
  ///
  /// The `Dji.platformVersion` gets the host (native platform) version (e.g. The iOS or Android version).
  /// Example:
  /// ```dart
  /// Future<void> _getPlatformVersion() async {
  ///   String platformVersion;
  ///   try {
  ///     platformVersion = await Dji.platformVersion ?? 'Unknown platform version';
  ///   } on PlatformException {
  ///     platformVersion = 'Failed to get platform version.';
  ///   }
  ///   if (!mounted) return;
  ///   setState(() {
  ///     _platformVersion = platformVersion;
  ///   });
  /// }
  /// ```
  /// Note:
  /// We check the `mounted` so that if the widget was removed from the tree while the asynchronous platform message was in flight, we want to discard the reply.
  static Future<String?> get platformVersion async {
    Version? version = await _api?.getPlatformVersion();
    return version?.string;
  }

  /// Gets the battery level.
  ///
  /// The `Dji.batteryLevel` gets the host (native platform) battery level (e.g. The iOS or Android battery level).
  /// Example:
  /// ```dart
  /// Future<void> _getBatteryLevel() async {
  ///   String batteryLevel;
  ///   try {
  ///     batteryLevel = await Dji.batteryLevel ?? 'Unknown battery level';
  ///   } on PlatformException {
  ///     batteryLevel = 'Failed to get battery level.';
  ///   }
  ///   if (!mounted) return;
  ///   setState(() {
  ///     _batteryLevel = batteryLevel;
  ///   });
  /// }
  /// ```
  static Future<int?> get batteryLevel async {
    Battery? battery = await _api?.getBatteryLevel();
    return battery?.level;
  }

  /// Registers the app at DJI
  ///
  /// The `Dji.registerApp` triggers the DJI SDK registration method.
  /// This is a required action, everytime we launch our app, and before we attempt to connect to the Drone.
  /// ```dart
  /// Future<void> _registerApp() async {
  ///   try {
  ///     await Dji.registerApp;
  ///     developer.log(
  ///       'registerApp succeeded',
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///   } on PlatformException catch (e) {
  ///     developer.log(
  ///       'registerApp PlatformException Error',
  ///       error: e,
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///   } catch (e) {
  ///     developer.log(
  ///       'registerApp Error',
  ///       error: e,
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///   }
  /// }
  /// ```
  static Future<void> get registerApp async {
    await _api?.registerApp();
  }

  /// Connects with the DJI Drone
  ///
  /// TBD...
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

  static Future<void> start({required Flight flight}) async {
    Map<String, dynamic> flightJson = flight.toJson();

    await _api?.start(jsonEncode(flightJson));
  }
}
