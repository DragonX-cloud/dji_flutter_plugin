import 'package:pigeon/pigeon.dart';

class Version {
  String string = '';
}

class Battery {
  int level = 0;
}

class Drone {
  String droneStatus = 'Disconnected';
}

@HostApi()
abstract class DjiHostApi {
  Version getPlatformVersion();
  Battery getBatteryLevel();
  void registerDjiApp();
}

@FlutterApi()
abstract class DjiFlutterApi {
  void setDroneStatus(Drone drone);
}
