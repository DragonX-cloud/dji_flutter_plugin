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
  /// Fetches the host (native platform) version (e.g. The iOS or Android version).
  ///
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
  /// Fetches the host (native platform) battery level (e.g. The iOS or Android battery level).
  ///
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

  /// Registers the app at DJI.
  ///
  /// Triggers the DJI SDK registration method.
  /// This is a required action, everytime we launch our app, and before we attempt to connect to the Drone.
  ///
  /// Once connected, the `DjiFlutterApi.setStatus()` method is triggered and the status is changed to "Registered".
  ///
  /// Example:
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
  static Future<void> registerApp() async {
    await _api?.registerApp();
  }

  /// Connects with the DJI Drone.
  ///
  /// The Remote Controller and the DJI Drone need to be turned on.
  /// The Remote Controller needs to be connected by USB cable to the mobile device running the app.
  /// Once connected, the `DjiFlutterApi.setStatus()` method is triggered and the status is changed to "Connected".
  ///
  /// Example:
  static Future<void> connectDrone() async {
    await _api?.connectDrone();
  }

  /// Disconnects from the DJI Drone.
  ///
  /// Once disconnected, the `DjiFlutterApi.setStatus()` method is triggered and the status is changed to "Disconnected".
  static Future<void> disconnectDrone() async {
    await _api?.disconnectDrone();
  }

  /// Starts Listening to DJI Drone status changes.
  ///
  /// The `DjiFlutterApi.setStatus()` method is used, and the properties of the Drone class are updated in real time.
  static Future<void> delegateDrone() async {
    await _api?.delegateDrone();
  }

  /// Triggers the DJI Drone Take Off action.
  ///
  /// Commands the Drone to start take-off.
  ///
  /// Example:
  /// ```
  /// Future<void> _takeOff() async {
  ///   try {
  ///     await Dji.takeOff;
  ///     developer.log(
  ///       'Takeoff succeeded',
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///   } on PlatformException catch (e) {
  ///     developer.log(
  ///       'Takeoff PlatformException Error',
  ///       error: e,
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///   } catch (e) {
  ///     developer.log(
  ///       'Takeoff Error',
  ///       error: e,
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///   }
  /// }
  /// ```
  static Future<void> takeOff() async {
    await _api?.takeOff();
  }

  /// Triggers the DJI Drone Land action.
  ///
  /// Commands the Drone to start landing.
  ///
  /// Example:
  /// ```
  /// Future<void> _land() async {
  ///   try {
  ///     await Dji.land;
  ///     developer.log(
  ///       'Land succeeded',
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///   } on PlatformException catch (e) {
  ///     developer.log(
  ///       'Land PlatformException Error',
  ///       error: e,
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///   } catch (e) {
  ///     developer.log(
  ///       'Land Error',
  ///       error: e,
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///   }
  /// }
  /// ```
  static Future<void> land() async {
    await _api?.land();
  }

  // /// Triggers the DJI Drone pre-defined Timeline.
  // ///
  // @Deprecated('Use [start] instead.')
  // static Future<void> timeline() async {
  //   await _api?.timeline();
  // }

  /// Starts the DJI Drone Flight Timeline.
  ///
  /// The [start()] method receives a [flight] object (Flight Timeline) and commands the Drone to start executing it.
  ///
  /// The [Flight] class defines the different flight properties (e.g. location, waypoint, etc.) and provides tools to convert from and to JSON.
  ///
  /// In the example below, we first validate that the `DroneHomeLocation` exists and then define our Flight object, which includes several Flight Elements.
  ///
  /// A Flight Element has several types:
  /// - takeOff
  /// - land
  /// - waypointMission
  /// - singleShootPhoto
  /// - startRecordVideo
  /// - stopRecordVideo
  ///
  /// The `waypointMission` consists of a list of waypoints.
  /// Each waypoint can be defined in two ways: `location` or `vector`.
  ///
  /// **Location** defines a waypoint by Latitude, Longitude and Altitude.
  ///
  /// **Vector** defines a waypoint in relation to the "point of interest".
  /// It's defined by 3 properties as follows:
  /// - `distanceFromPointOfInterest`
  /// 	- The distance in meters between the "point of interest" and the Drone.
  /// - `headingRelativeToPointOfInterest`
  /// 	- If you imagine a line between the "point of interest" (e.g. where you stand) and the Drone's Home Location - this is heading "0".
  /// 	- So the value of `headingRelativeToPointOfInterest` is the angle between heading "0" and where you want the Drone to be.
  /// 	- A positive heading angle is to your right. While a negative angle is to your left.
  /// - `destinationAltitude`
  /// 	- This is the Drone's altitude at the waypoint.
  ///
  /// **Explanation by example:**
  /// Imagine you are the "point of interest", holding a "laser pointer".
  /// Everything is relative to the "line" between you and the Drone.
  /// If you point the laser to the Drone itself - that's "heading 0".
  /// If you want the first waypoint to be 30 degrees to your right, at a distance of 100 meters and altitude of 10 meters, you should set:
  /// ```
  /// 'vector': {
  ///   'distanceFromPointOfInterest': 100,
  ///   'headingRelativeToPointOfInterest': 30,
  ///   'destinationAltitude': 10,
  /// },
  /// ```
  ///
  /// A full example showing how to use the Flight object and use the `Dji.start` method:
  /// ```
  /// Future<void> _start() async {
  ///   try {
  ///     droneHomeLocation = FlightLocation(
  ///         latitude: 32.2181125, longitude: 34.8674920, altitude: 0);
  ///
  ///     if (droneHomeLocation == null) {
  ///       developer.log(
  ///           'No drone home location exist - unable to start the flight',
  ///           name: kLogKindDjiFlutterPlugin);
  ///       return;
  ///     }
  ///
  ///     Flight flight = Flight.fromJson({
  ///       'timeline': [
  ///         {
  ///           'type': 'takeOff',
  ///         },
  ///         {
  ///           'type': 'startRecordVideo',
  ///         },
  ///         {
  ///           'type': 'waypointMission',
  ///           /// For example purposes, we set our Point of Interest a few meters away, relative to the Drone's Home Location
  ///           'pointOfInterest': {
  ///             'latitude': droneHomeLocation!.latitude + (5 * 0.00000899322),
  ///             'longitude': droneHomeLocation!.longitude + (5 * 0.00000899322),
  ///             'altitude': droneHomeLocation!.altitude,
  ///           },
  ///           'maxFlightSpeed':
  ///               15.0, /// Max Flight Speed is 15.0. If you enter a higher value - the waypoint mission won't start due to DJI limits.
  ///           'autoFlightSpeed': 10.0,
  ///           'finishedAction': 'noAction',
  ///           'headingMode': 'towardPointOfInterest',
  ///           'flightPathMode': 'curved',
  ///           'rotateGimbalPitch': true,
  ///           'exitMissionOnRCSignalLost': true,
  ///           'waypoints': [
  ///             {
  ///               // 'location': {
  ///               //   'latitude': 32.2181125,
  ///               //   'longitude': 34.8674920,
  ///               //   'altitude': 20.0,
  ///               // },
  ///               'vector': {
  ///                 'distanceFromPointOfInterest': 20,
  ///                 'headingRelativeToPointOfInterest': 45,
  ///                 'destinationAltitude': 5,
  ///               },
  ///               // 'heading': 0,
  ///               'cornerRadiusInMeters': 5,
  ///               'turnMode': 'clockwise',
  ///               // 'gimbalPitch': 0,
  ///             },
  ///             {
  ///               // 'location': {
  ///               //   'latitude': 32.2181125,
  ///               //   'longitude': 34.8674920,
  ///               //   'altitude': 5.0,
  ///               // },
  ///               'vector': {
  ///                 'distanceFromPointOfInterest': 10,
  ///                 'headingRelativeToPointOfInterest': -45,
  ///                 'destinationAltitude': 3,
  ///               },
  ///               // 'heading': 0,
  ///               'cornerRadiusInMeters': 5,
  ///               'turnMode': 'clockwise',
  ///               // 'gimbalPitch': 0,
  ///             },
  ///           ],
  ///         },
  ///         {
  ///           'type': 'stopRecordVideo',
  ///         },
  ///         {
  ///           'type': 'singleShootPhoto',
  ///         },
  ///         {
  ///           'type': 'land',
  ///         },
  ///       ],
  ///     });
  ///
  ///     // Converting any vector definitions in waypoint-mission to locations
  ///     for (dynamic element in flight.timeline) {
  ///       if (element.type == FlightElementType.waypointMission) {
  ///         CoordinatesConvertion
  ///             .convertWaypointMissionVectorsToLocationsWithGimbalPitch(
  ///                 flightElementWaypointMission: element,
  ///                 droneHomeLocation: droneHomeLocation!);
  ///       }
  ///     }
  ///
  ///     developer.log(
  ///       'Flight Object: ${jsonEncode(flight)}',
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///
  ///     await Dji.start(flight: flight);
  ///     developer.log(
  ///       'Start Flight succeeded',
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///   } on PlatformException catch (e) {
  ///     developer.log(
  ///       'Start Flight PlatformException Error',
  ///       error: e,
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///   } catch (e) {
  ///     developer.log(
  ///       'Start Flight Error',
  ///       error: e,
  ///       name: kLogKindDjiFlutterPlugin,
  ///     );
  ///   }
  /// }
  /// ```
  static Future<void> start({required Flight flight}) async {
    Map<String, dynamic> flightJson = flight.toJson();

    await _api?.start(jsonEncode(flightJson));
  }

  /// Update Mobile Remote Controller Sticks Data (via Wifi)
  ///
  /// Controls the mobile remote controller - an on-screen sticks controller.
  /// Available when the drone is connected via Wifi.
  static Future<void> mobileRemoteController({
    required bool enabled,
    required double leftStickHorizontal,
    required double leftStickVertical,
    required double rightStickHorizontal,
    required double rightStickVertical,
  }) async {
    await _api?.mobileRemoteController(
      enabled,
      leftStickHorizontal,
      leftStickVertical,
      rightStickHorizontal,
      rightStickVertical,
    );
  }

  /// Update Virtual Stick flight controller data (via physical remote controller)
  ///
  /// Control whether the virtual-stick mode is [enabled], and the [pitch], [roll], [yaw] and [verticalThrottle] of the Virtual Stick flight controller.
  /// Available only when the drone is connected to the physical remote controller.
  static Future<void> virtualStick({
    required bool enabled,
    required double pitch,
    required double roll,
    required double yaw,
    required double verticalThrottle,
  }) async {
    await _api?.virtualStick(
      enabled,
      pitch,
      roll,
      yaw,
      verticalThrottle,
    );
  }

  /// Update Gimbal pitch value in degrees
  ///
  /// Controls the Gimbal pitch in [degrees] (-90..0) in Absolute Mode.
  /// An angle of "0" degrees is aligned with the drone's "nose" (heading), and -90 degrees is the gimbal pointing the camera all the way down.
  static Future<void> gimbalRotatePitch({
    required double degrees,
  }) async {
    await _api?.gimbalRotatePitch(
      degrees,
    );
  }

  /// Get the media files list from the Drone (SD card).
  ///
  /// Returns a list of Media files.
  /// The index of each file is used to download or delete the file.
  static Future<List<Media?>?> getMediaList() async {
    final mediaList = await _api?.getMediaList();
    return mediaList;
  }

  /// Downloads a specific media file from the Drone's SD card (by Index).
  ///
  /// The [fileIndex] is used to locate the relevant file from the Media List and download it.
  /// The [getMediaList()] must be triggered before using [downloadMedia()].
  static Future<String?> downloadMedia(int fileIndex) async {
    final fileUrl = await _api?.downloadMedia(fileIndex);
    return fileUrl;
  }

  /// Deletes a specific media file from the Drone's SD card (by Index).
  ///
  /// The [fileIndex] is used to locate the relevant file from the Media List and delete it.
  /// The [getMediaList()] must be triggered before using [deleteMedia()].
  static Future<bool?> deleteMedia(int fileIndex) async {
    final success = await _api?.deleteMedia(fileIndex);
    return success;
  }

  /// Starts the DJI Video Feeder.
  ///
  /// Triggers the DJI Camera Preview and streams rawvideo YUV420p byte-stream to the `DjiFlutterApi.sendVideo(Stream stream)` method.
  /// The `Stream` class has a `data` property of type `Uint8List` optional.
  /// The byte-stream can be converted to MP4, HLS or any other format using FFMPEG (see example code).
  static Future<void> videoFeedStart() async {
    await _api?.videoFeedStart();
  }

  /// Stops the DJI Video Feeder.
  ///
  static Future<void> videoFeedStop() async {
    await _api?.videoFeedStop();
  }

  /// Starts the DJI Video Recorder.
  ///
  static Future<void> videoRecordStart() async {
    await _api?.videoRecordStart();
  }

  /// Stops the DJI Video Recorder.
  ///
  static Future<void> videoRecordStop() async {
    await _api?.videoRecordStop();
  }
}
