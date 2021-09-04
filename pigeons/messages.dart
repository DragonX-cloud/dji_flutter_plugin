import 'package:dji/flight.dart';
import 'package:pigeon/pigeon.dart';

class Version {
  String string = '';
}

class Battery {
  int level = 0;
}

class Drone {
  String status = 'Disconnected'; // Disconnected, Registered, Connected
  double batteryPercent = 0.0;
  double altitude = 0.0;
  double latitude = 0.0;
  double longitude = 0.0;
  double speed = 0.0;
  double roll = 0.0;
  double pitch = 0.0;
  double yaw = 0.0;
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
  void start(Flight flight);
}

@FlutterApi()
abstract class DjiFlutterApi {
  void setDroneStatus(Drone drone);
}
