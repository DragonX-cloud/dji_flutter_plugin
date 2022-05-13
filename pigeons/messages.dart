import 'package:flutter/services.dart';
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

class Media {
  String? fileName;
  String? fileUrl;
  int? fileIndex;
}

class Stream {
  Uint8List? data;
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
  void start(String flightJson);
  List<Media> getMediaList();
  String downloadMedia(int fileIndex);
  bool deleteMedia(int fileIndex);
}

@FlutterApi()
abstract class DjiFlutterApi {
  void setStatus(Drone drone);
  void sendVideo(Stream stream);
}
