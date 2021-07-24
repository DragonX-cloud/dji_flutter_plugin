import 'dart:async';
import 'messages.dart';

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
}
