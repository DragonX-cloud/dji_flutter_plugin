import 'package:pigeon/pigeon.dart';

class Version {
  String string = '';
}

class Battery {
  int level = 0;
}

class Drone {
  String status = 'Disconnected'; // Disconnected, Registered, Connected
  double altitude = 0.0;
  double latitude = 0.0;
  double longitude = 0.0;
}

@HostApi()
abstract class DjiHostApi {
  Version getPlatformVersion();
  Battery getBatteryLevel();
  void registerApp();
  void connectDrone();
  void disconnectDrone();
}

@FlutterApi()
abstract class DjiFlutterApi {
  void setDroneStatus(Drone drone);
}
