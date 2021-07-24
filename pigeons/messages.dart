import 'package:pigeon/pigeon.dart';

class Version {
  String string = '';
}

class Battery {
  int level = 0;
}

class Drone {
  String status = 'Disconnected'; // Disconnected, Registered, Connected
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
