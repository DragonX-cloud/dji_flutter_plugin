import 'package:pigeon/pigeon.dart';

class Version {
  String? string;
}

class Battery {
  int? level;
}

class Drone {
  String? status;
  double? batteryPercent;
  double? altitude;
  double? latitude;
  double? longitude;
  double? speed;
  double? roll;
  double? pitch;
  double? yaw;
}

@HostApi()
abstract class DjiHostApi {
  Version getPlatformVersion();
  Battery getBatteryLevel();
  void registerApp();
  void connectDrone();
  void disconnectDrone();
  void delegateDrone();
  void takeOff();
  void land();
  void timeline();
  void start(String flightJson);
  void downloadAllMedia();
  void deleteAllMedia();
}

@FlutterApi()
abstract class DjiFlutterApi {
  void setStatus(Drone drone);
}
