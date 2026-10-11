// To regenerate the platform interfaces, run from the package root:
// dart run pigeon --input pigeons/messages.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/messages.dart',
    dartPackageName: 'dji',
    kotlinOut: 'android/src/main/kotlin/cloud/dragonx/plugin/flutter/dji/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'cloud.dragonx.plugin.flutter.dji'),
    swiftOut: 'ios/Classes/Messages.g.swift',
  ),
)
class Version {
  String? string;
}

class Battery {
  int? level;
}

class Drone {
  String? status;
  String? error;
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
  void mobileRemoteController(
    bool enabled,
    double leftStickHorizontal,
    double leftStickVertical,
    double rightStickHorizontal,
    double rightStickVertical,
  );
  void virtualStick(
    bool enabled,
    double pitch,
    double roll,
    double yaw,
    double verticalThrottle,
  );
  void gimbalRotatePitch(double degrees);
  @async
  List<Media> getMediaList();
  @async
  String downloadMedia(int fileIndex);
  @async
  bool deleteMedia(int fileIndex);
  void videoFeedStart();
  void videoFeedStop();
  void videoRecordStart();
  void videoRecordStop();
}

@FlutterApi()
abstract class DjiFlutterApi {
  void setStatus(Drone drone);
  void sendVideo(Stream stream);
}
