import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:io';
// import 'dart:typed_data' show ByteBuffer, ByteData, Uint8List;

import 'package:dji/flight.dart';
import 'package:dji/messages.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:dji/dji.dart';

import 'constants.dart';

import 'package:path_provider/path_provider.dart';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';

// import 'package:video_player/video_player.dart' as VP;
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
// import 'package:dart_vlc/dart_vlc.dart' as VLC;
// import 'package:flutter_playout/video.dart';
// import 'package:native_video_view/native_video_view.dart';

// import 'package:dio/dio.dart';

class ExampleWidget extends StatefulWidget {
  const ExampleWidget({Key? key}) : super(key: key);

  @override
  _ExampleWidgetState createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget>
    implements DjiFlutterApi {
  String _platformVersion = 'Unknown';
  String _droneStatus = 'Disconnected';
  String _droneBatteryPercent = '0';
  String _droneAltitude = '0.0';
  String _droneLatitude = '0.0';
  String _droneLongitude = '0.0';
  String _droneSpeed = '0.0';
  String _droneRoll = '0.0';
  String _dronePitch = '0.0';
  String _droneYaw = '0.0';

  VlcPlayerController? _vlcController;
  // VLC.Player? _vlcPlayer;
  // VideoViewController? _nativeVideoViewController;
  // VP.VideoPlayerController? _vpController;
  int? _ffmpegKitSessionId;

  File? _videoFeedFile;
  IOSink? _videoFeedSink;

  @override
  void initState() {
    super.initState();

    DjiFlutterApi.setup(this);

    _getPlatformVersion();
  }

  // This function is triggered by the Native Host side whenever the Drone Status is changed.
  @override
  void setStatus(Drone drone) async {
    setState(() {
      _droneStatus = drone.status ?? 'Disconnected';
      _droneAltitude = drone.altitude?.toStringAsFixed(2) ?? '0.0';
      _droneBatteryPercent = drone.batteryPercent?.toStringAsFixed(0) ?? '0';
      _droneLatitude = drone.latitude?.toStringAsFixed(7) ?? '0.0';
      _droneLongitude = drone.longitude?.toStringAsFixed(7) ?? '0.0';
      _droneSpeed = drone.speed?.toStringAsFixed(2) ?? '0.0';
      _droneRoll = drone.roll?.toStringAsFixed(3) ?? '0.0';
      _dronePitch = drone.pitch?.toStringAsFixed(3) ?? '0.0';
      _droneYaw = drone.yaw?.toStringAsFixed(3) ?? '0.0';
    });
  }

  // This function is triggered by the Native Host side whenever a video byte-stream data is sent
  @override
  void sendVideo(Stream stream) {
    if (stream.data != null && _videoFeedFile != null) {
      // final dataLength = stream.data!.lengthInBytes;
      // developer.log(
      //   'Send Video - Data Length: $dataLength',
      //   name: kLogKindDjiFlutterPlugin,
      // );

      _videoFeedSink?.add(stream.data!);
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _getPlatformVersion() async {
    String platformVersion;

    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await Dji.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _registerApp() async {
    try {
      developer.log(
        'registerApp requested',
        name: kLogKindDjiFlutterPlugin,
      );
      await Dji.registerApp();
    } on PlatformException catch (e) {
      developer.log(
        'registerApp PlatformException Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    } catch (e) {
      developer.log(
        'registerApp Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    }
  }

  Future<void> _connectDrone() async {
    try {
      developer.log(
        'connectDrone requested',
        name: kLogKindDjiFlutterPlugin,
      );
      await Dji.connectDrone();
    } on PlatformException catch (e) {
      developer.log(
        'connectDrone PlatformException Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    } catch (e) {
      developer.log(
        'connectDrone Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    }
  }

  // Future<void> _disconnectDrone() async {
  //   try {
  //     developer.log(
  //       'disconnectDrone requested',
  //       name: kLogKindDjiFlutterPlugin,
  //     );
  //     await Dji.disconnectDrone();
  //   } on PlatformException catch (e) {
  //     developer.log(
  //       'disconnectDrone PlatformException Error',
  //       error: e,
  //       name: kLogKindDjiFlutterPlugin,
  //     );
  //   } catch (e) {
  //     developer.log(
  //       'disconnectDrone Error',
  //       error: e,
  //       name: kLogKindDjiFlutterPlugin,
  //     );
  //   }
  // }

  Future<void> _delegateDrone() async {
    try {
      developer.log(
        'delegateDrone requested',
        name: kLogKindDjiFlutterPlugin,
      );
      await Dji.delegateDrone();
    } on PlatformException catch (e) {
      developer.log(
        'delegateDrone PlatformException Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    } catch (e) {
      developer.log(
        'delegateDrone Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    }
  }

  Future<void> _takeOff() async {
    try {
      developer.log(
        'Takeoff requested',
        name: kLogKindDjiFlutterPlugin,
      );
      await Dji.takeOff();
    } on PlatformException catch (e) {
      developer.log(
        'Takeoff PlatformException Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    } catch (e) {
      developer.log(
        'Takeoff Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    }
  }

  Future<void> _land() async {
    try {
      developer.log(
        'Land requested',
        name: kLogKindDjiFlutterPlugin,
      );
      await Dji.land();
    } on PlatformException catch (e) {
      developer.log(
        'Land PlatformException Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    } catch (e) {
      developer.log(
        'Land Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    }
  }

  // Future<void> _timeline() async {
  //   try {
  //     developer.log(
  //       'Timeline requested',
  //       name: kLogKindDjiFlutterPlugin,
  //     );
  //     await Dji.timeline();
  //   } on PlatformException catch (e) {
  //     developer.log(
  //       'Timeline PlatformException Error',
  //       error: e,
  //       name: kLogKindDjiFlutterPlugin,
  //     );
  //   } catch (e) {
  //     developer.log(
  //       'Timeline Error',
  //       error: e,
  //       name: kLogKindDjiFlutterPlugin,
  //     );
  //   }
  // }

  Future<void> _start() async {
    try {
      // final droneHomeLocation = FlightLocation(
      //     latitude: 32.2181125, longitude: 34.8674920, altitude: 0);
      // final droneHomeLocation =
      //     FlightLocation(latitude: 32.26215, longitude: 34.88217, altitude: 0);

      // In this example, we set the point-of-interest as a few meters away from the Drone's home location.
      // So before we start the Flight Timeline - we set the drone home location here, based on its current state.
      final droneHomeLocation = FlightLocation(
        latitude: double.tryParse(_droneLatitude) ?? 0,
        longitude: double.tryParse(_droneLongitude) ?? 0,
        altitude: double.tryParse(_droneAltitude) ?? 0,
      );

      if (droneHomeLocation.latitude != 0 && droneHomeLocation.longitude != 0) {
        developer.log(
            'Invalid drone\'s home location - unable to start the flight',
            name: kLogKindDjiFlutterPlugin);
        return;
      }

      Flight flight = Flight.fromJson({
        'timeline': [
          {
            'type': 'takeOff',
          },
          {
            'type': 'startRecordVideo',
          },
          {
            'type': 'waypointMission',
            // For example purposes, we set our Point of Interest a few meters to the north (in relation to the Drone's Home Location).
            // Note: Setting the precision to 8 decimals (~1.1mm accuracy, which is the GPS limit).
            'pointOfInterest': {
              'latitude': ((droneHomeLocation.latitude + (20 * 0.00000899322)) *
                          100000000)
                      .round() /
                  100000000,
              'longitude':
                  ((droneHomeLocation.longitude + (0 * 0.00000899322)) *
                              100000000)
                          .round() /
                      100000000,
              'altitude': droneHomeLocation.altitude,
            },
            'maxFlightSpeed':
                15.0, // Max Flight Speed is 15.0. If you enter a higher value - the waypoint mission won't start due to DJI limits.
            'autoFlightSpeed': 10.0,
            'finishedAction': 'noAction',
            'headingMode': 'towardPointOfInterest',
            'flightPathMode': 'curved',
            'rotateGimbalPitch': true,
            'exitMissionOnRCSignalLost': true,
            'waypoints': [
              // {
              // 'location': {
              //   'latitude': 32.2181125,
              //   'longitude': 34.8674920,
              //   'altitude': 20.0,
              // },
              // 'heading': 0,
              // 'cornerRadiusInMeters': 5,
              // 'turnMode': 'clockwise',
              // 'gimbalPitch': 0,
              // },

              // This initial waypoint is important, the DJI SDK ignores the cornerRadiusInMeters of the first waypoint (and the turn wouldl not be "round").
              // Therefore, we add this initial waypoint, just to get the Drone to a specific height, and when it reaches the second waypoint - the cornerRadiusInMeters is treated properly by the DJI SDK.
              {
                'location': {
                  'latitude': droneHomeLocation.latitude,
                  'longitude': droneHomeLocation.longitude,
                  'altitude': 20,
                },
                'cornerRadiusInMeters': 5,
                'turnMode': 'counterClockwise',
              },
              {
                'vector': {
                  'distanceFromPointOfInterest': 20,
                  'headingRelativeToPointOfInterest': -45,
                  'destinationAltitude': 10,
                },
                'cornerRadiusInMeters': 5,
                'turnMode': 'counterClockwise',
              },
              {
                'vector': {
                  'distanceFromPointOfInterest': 20,
                  'headingRelativeToPointOfInterest': -135,
                  'destinationAltitude': 10,
                },
                'cornerRadiusInMeters': 5,
                'turnMode': 'counterClockwise',
              },
              {
                'vector': {
                  'distanceFromPointOfInterest': 20,
                  'headingRelativeToPointOfInterest': -225,
                  'destinationAltitude': 20,
                },
                'cornerRadiusInMeters': 5,
                'turnMode': 'counterClockwise',
              },
              {
                'vector': {
                  'distanceFromPointOfInterest': 20,
                  'headingRelativeToPointOfInterest': -315,
                  'destinationAltitude': 10,
                },
                'cornerRadiusInMeters': 5,
                'turnMode': 'counterClockwise',
              },
              {
                'location': {
                  'latitude': droneHomeLocation.latitude,
                  'longitude': droneHomeLocation.longitude,
                  'altitude': 10,
                },
                'cornerRadiusInMeters': 5,
                'turnMode': 'counterClockwise',
              },
            ],
          },
          {
            'type': 'stopRecordVideo',
          },
          {
            'type': 'singleShootPhoto',
          },
          {
            'type': 'land',
          },
        ],
      });

      // Converting any vector definitions in waypoint-mission to locations
      for (dynamic element in flight.timeline) {
        if (element.type == FlightElementType.waypointMission) {
          CoordinatesConvertion
              .convertWaypointMissionVectorsToLocationsWithGimbalPitch(
                  flightElementWaypointMission: element,
                  droneHomeLocation: droneHomeLocation);
        }
      }

      developer.log(
        'Flight Object: ${jsonEncode(flight)}',
        name: kLogKindDjiFlutterPlugin,
      );

      developer.log(
        'Start Flight requested',
        name: kLogKindDjiFlutterPlugin,
      );
      await Dji.start(flight: flight);
    } on PlatformException catch (e) {
      developer.log(
        'Start Flight PlatformException Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    } catch (e) {
      developer.log(
        'Start Flight Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    }
  }

  Future<List<Media?>?> _getMediaList() async {
    List<Media?>? mediaList;

    try {
      developer.log(
        'Get Media List requested',
        name: kLogKindDjiFlutterPlugin,
      );

      mediaList = await Dji.getMediaList();

      developer.log(
        'Media List: $mediaList',
        name: kLogKindDjiFlutterPlugin,
      );
    } on PlatformException catch (e) {
      developer.log(
        'Get Media List PlatformException Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    } catch (e) {
      developer.log(
        'Get Media List Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    }

    return mediaList;
  }

  Future<void> _download() async {
    try {
      developer.log(
        'Download requested',
        name: kLogKindDjiFlutterPlugin,
      );
      // Downloading media file number "0" (a.k.a index: 0)
      final fileUrl = await Dji.downloadMedia(0);
      developer.log(
        'Download successful: $fileUrl',
        name: kLogKindDjiFlutterPlugin,
      );
    } on PlatformException catch (e) {
      developer.log(
        'Download PlatformException Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    } catch (e) {
      developer.log(
        'Download Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    }
  }

  Future<void> _delete() async {
    try {
      developer.log(
        'Delete requested',
        name: kLogKindDjiFlutterPlugin,
      );
      // Deleting media file number "0" (a.k.a index: 0)
      final deleted = await Dji.deleteMedia(0);
      if (deleted == true) {
        developer.log(
          'Deleted successfully',
          name: kLogKindDjiFlutterPlugin,
        );
      } else {
        developer.log(
          'Delete failed',
          name: kLogKindDjiFlutterPlugin,
        );
      }
    } on PlatformException catch (e) {
      developer.log(
        'Delete PlatformException Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    } catch (e) {
      developer.log(
        'Delete Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    }
  }

  Future<void> _videoFeedStart() async {
    try {
      developer.log(
        'Video Feed Start requested',
        name: kLogKindDjiFlutterPlugin,
      );

      FFmpegKitConfig.registerNewFFmpegPipe().then((inputPipe) async {
        if (inputPipe == null) {
          developer.log(
            'Video Feed Start failed - no Input Pipe',
            name: kLogKindDjiFlutterPlugin,
          );

          return;
        }

        final Directory directory = await getTemporaryDirectory();

        // final String outputPath = directory.path + '/output.mp4';

        // final String downloadPath = directory.path + '/download_stream.mp4';
        // final File downloadFile = File(downloadPath);

        const String exampleAssetPath = 'videos/example.mov';
        // setState(() {
        //   _vlcController = VlcPlayerController.asset(
        //     exampleAssetPath,
        //   );
        // });
        // return;

        ByteData data = await rootBundle.load(exampleAssetPath);
        String exampleStreamPath = directory.path + '/example_stream.mov';
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(exampleStreamPath).writeAsBytes(bytes);
        // setState(() {
        //   _vlcController = VlcPlayerController.file(
        //     File(exampleStreamPath),
        //   );
        // });
        // return;

        // final String videoFeedPath = directory.path + '/video_feed.h264';
        final String videoFeedPath = inputPipe;
        _videoFeedFile = File(videoFeedPath);
        // final String outputPipe = directory.path + '/tmp.mp4';
        // final File outputFile = File(outputPipe);

        developer.log(
          'Video Feed Start - video feed path: $videoFeedPath',
          name: kLogKindDjiFlutterPlugin,
        );

        // if (await outputFile.exists() == true) {
        //   await outputFile.delete();
        // }

        // try {
        //   Dio().download(
        //       'https://jsoncompare.org/LearningContainer/SampleFiles/Video/MP4/Sample-MP4-Video-File-Download.mp4',
        //       downloadPath);
        // } catch (e) {
        //   developer.log(
        //     'Video Feed Start - Dio download error: $e',
        //     name: kLogKindDjiFlutterPlugin,
        //   );
        // }
        // await Future.delayed(const Duration(seconds: 5));
        // var downloadStream = downloadFile.openRead();

        // downloadStream.listen((data) {
        //   print(data.length.toString());
        //   _videoFeedSink?.add(data);
        // }, onError: (e) {
        //   print(e);
        // });

        // Waiting 1 second for the the input pipe to kick in.
        // await Future.delayed(const Duration(seconds: 2));

        // FFmpegKitConfig.writeToPipe(inputStream, inputPipe);

        // final Directory directory = await getApplicationDocumentsDirectory();
        // final String path = directory.parent.path + '/tmp';
        // final String inputStream = path + '/video_feed.h264';

        FFmpegKitConfig.registerNewFFmpegPipe().then((outputPipe) async {
          if (outputPipe == null) {
            developer.log(
              'Video Feed Start failed - no Output Pipe',
              name: kLogKindDjiFlutterPlugin,
            );

            return;
          }

          FFmpegKitConfig.closeFFmpegPipe(outputPipe);

          developer.log(
            'Video Feed Start outputPipe: $outputPipe',
            name: kLogKindDjiFlutterPlugin,
          );

          // if (_ffmpegKitSessionId != null) {
          //   FFmpegKit.cancel(_ffmpegKitSessionId);
          // }

          // _vpController = VP.VideoPlayerController.network(
          //   'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          // )..initialize().then((_) {
          //     // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          //     setState(() {});
          //   });
          // return;

          // Initializing the VLC Dart Player
          // await VLC.DartVLC.initialize(useFlutterNativeView: true);
          // _vlcPlayer = VLC.Player(
          //   id: 0,
          //   videoDimensions: const VLC.VideoDimensions(640, 360),
          //   // registerTexture: !Platform.isWindows,
          // );

          // _vlcPlayer?.currentStream.listen((current) {
          //   developer.log(
          //     'VLC current stream: $current',
          //     name: kLogKindDjiFlutterPlugin,
          //   );
          // });
          // _vlcPlayer?.positionStream.listen((position) {
          //   developer.log(
          //     'VLC position: $position',
          //     name: kLogKindDjiFlutterPlugin,
          //   );
          // });
          // _vlcPlayer?.playbackStream.listen((playback) {
          //   developer.log(
          //     'VLC position: $playback',
          //     name: kLogKindDjiFlutterPlugin,
          //   );
          // });
          // _vlcPlayer?.generalStream.listen((general) {
          //   developer.log(
          //     'VLC general: $general',
          //     name: kLogKindDjiFlutterPlugin,
          //   );
          // });
          // _vlcPlayer?.videoDimensionsStream.listen((videoDimensions) {
          //   developer.log(
          //     'VLC videoDimensions: $videoDimensions',
          //     name: kLogKindDjiFlutterPlugin,
          //   );
          // });
          // _vlcPlayer?.bufferingProgressStream.listen(
          //   (bufferingProgress) {
          //     developer.log(
          //       'VLC bufferingProgress: $bufferingProgress',
          //       name: kLogKindDjiFlutterPlugin,
          //     );
          //   },
          // );
          // _vlcPlayer?.errorStream.listen((event) {
          //   developer.log(
          //     'VLC error: $event',
          //     name: kLogKindDjiFlutterPlugin,
          //   );
          // });

          _videoFeedSink = _videoFeedFile?.openWrite();
          // FFmpegKitConfig.writeToPipe(exampleStreamPath, inputPipe).then((_) {
          //   FFmpegKitConfig.closeFFmpegPipe(inputPipe);
          // });
          // await Future.delayed(const Duration(seconds: 3));

          setState(() {
            // Initializing the VPC Player
            // _vpController = VP.VideoPlayerController.file(File(outputPath))
            //   ..initialize().then((_) {
            //     // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
            //     setState(() {
            //       developer.log(
            //         'Video Player initialized',
            //         name: kLogKindDjiFlutterPlugin,
            //       );
            //     });
            //   });

            _vlcController ??= VlcPlayerController.file(
              // File(outputPipe),
              File(outputPipe),
              autoInitialize: true,
              autoPlay: false,
              hwAcc: HwAcc.auto,
              options: VlcPlayerOptions(
                video: VlcVideoOptions(
                  [
                    VlcVideoOptions.dropLateFrames(true),
                    VlcVideoOptions.skipFrames(true),
                  ],
                ),
                advanced: VlcAdvancedOptions([
                  VlcAdvancedOptions.networkCaching(0),
                  VlcAdvancedOptions.liveCaching(0),
                  VlcAdvancedOptions.clockSynchronization(0),
                ]),
                sout: VlcStreamOutputOptions([
                  VlcStreamOutputOptions.soutMuxCaching(0),
                ]),
                extras: [],
              ),
            );
          });

          _vlcController?.addOnInitListener(() async {
            developer.log(
              'VLC Player: addOnInitListener - initialized',
              name: kLogKindDjiFlutterPlugin,
            );

            // await Dji.videoFeedStart();

            // setState(() {
            //   _vlcController?.play();
            // });

            // _vlcController?.setMediaFromFile(
            //   File(outputPipe),
            //   autoPlay: true,
            //   hwAcc: HwAcc.full,
            // );
          });

          // https://ffmpeg.org/ffmpeg-formats.html
          await FFmpegKit.executeAsync(
            // '-y -loglevel error -nostats -probesize 128 -flags2 showall -f h264 -i $inputStream -f mp4 -movflags frag_keyframe+empty_moov $outputPipe',
            // '-y -flags2 showall -f h264 -i $videoFeedPath -f mp4 -movflags frag_keyframe+empty_moov $outputPipe',
            // '-y -probesize 32 -flags2 showall -f h264 -err_detect ignore_err -i $videoFeedPath -f mp4 -movflags frag_keyframe+empty_moov $outputPipe',
            // '-y -flags2 showall -f h264 -err_detect ignore_err -i $videoFeedPath -f mp4 -movflags frag_keyframe+empty_moov -r 25 $outputPipe',
            // '-y -flags2 showall -f h264 -err_detect ignore_err -i $videoFeedPath -f mpegts -r 25 -probesize 32 -fflags nobuffer -flags low_delay $outputPipe',
            // '-y -loglevel error -nostats -probesize 32 -err_detect ignore_err -flags low_delay -flags2 showall -f h264 -i $inputPipe -fflags discardcorrupt -fflags nobuffer -avioflags direct -flags low_delay -s 320x180 -r 15 -f hls -movflags frag_keyframe+empty_moov $outputPipe',
            // '-y -flags2 showall -f h264 -i $inputPipe -f mpegts udp://localhost:1337',
            // '-y -probesize 32 -flags2 showall -f h264 -i $videoFeedPath -fflags discardcorrupt -fflags nobuffer -avioflags direct -flags low_delay -s 640x360 -r 15 -f hls -hls_flags single_file -hls_time 0 -hls_list_size 0 -movflags frag_keyframe+empty_moov $outputPipe',
            // '-y -re -err_detect ignore_err -probesize 32 -fflags nobuffer -flags2 showall -f h264 -i $inputPipe -fflags discardcorrupt -fflags nobuffer -avioflags direct -flags low_delay -s 640x360 -r 15 -f hls -hls_flags split_by_time -hls_time 0 -hls_list_size 0 -hls_allow_cache 0 $outputPipe',
            // '-y -re -err_detect ignore_err -probesize 32 -fflags nobuffer -flags2 showall -f h264 -i $inputPipe -fflags discardcorrupt -fflags nobuffer -avioflags direct -flags low_delay -s 640x360 -r 15 -f hls -hls_flags split_by_time -hls_time 2 -hls_list_size 0 -hls_allow_cache 0 -live_start_index -1 $outputPipe',
            // '-y -re -err_detect ignore_err -probesize 32 -fflags nobuffer -f mov -i $exampleStreamPath -fflags discardcorrupt -fflags nobuffer -avioflags direct -flags low_delay -s 640x360 -r 15 -f hls -hls_flags split_by_time -hls_time 2 -hls_list_size 0 -hls_allow_cache 0 -live_start_index -1 $outputPipe',
            '-y -re -err_detect ignore_err -f mov -i $exampleStreamPath -fflags discardcorrupt -fflags nobuffer -avioflags direct -flags low_delay -s 640x360 -r 15 -f hls -hls_time 0 $outputPipe',
            // '-y -re -f mov -i $exampleStreamPath -fflags discardcorrupt -fflags nobuffer -avioflags direct -flags low_delay -s 640x360 -r 15 -f hls -hls_time 0 -hls_allow_cache 0 $outputPipe',
            (session) async {
              _ffmpegKitSessionId = session.getSessionId();

              developer.log(
                'FFmpegKit.executeAsync sessionId: $_ffmpegKitSessionId',
                name: kLogKindDjiFlutterPlugin,
              );
            },
            (log) {
              if (log.getLevel() < 32) {
                developer.log(
                  'FFmpegKit.executeAsync logs: ${log.getMessage()}',
                  name: kLogKindDjiFlutterPlugin,
                );
              }
            },
            (statistics) async {
              developer.log(
                'FFmpegKit.executeAsync statistics - frame: ${statistics.getVideoFrameNumber()}, time: ${statistics.getTime()}',
                name: kLogKindDjiFlutterPlugin,
              );

              if (statistics.getTime() >= 1500 &&
                  await _vlcController?.isPlaying() == false) {
                // Initializing the VLC Player
                // https://wiki.videolan.org/Uncommon_uses/
                setState(() {
                  developer.log(
                    'VLC Player: play',
                    name: kLogKindDjiFlutterPlugin,
                  );
                  _vlcController?.play();

                  // _nativeVideoViewController
                  //     ?.setVideoSource(
                  //   outputPath,
                  //   // 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_20MB.mp4',
                  //   sourceType: VideoSourceType.file,
                  //   requestAudioFocus: false,
                  // )
                  //     .then((_) {
                  //   developer.log(
                  //     'Native Video View: play',
                  //     name: kLogKindDjiFlutterPlugin,
                  //   );

                  //   _vlcController?.play();
                  //   _nativeVideoViewController?.play();
                  // }).onError((error, stackTrace) {
                  //   developer.log(
                  //     'Native Video View: error',
                  //     error: error,
                  //     name: kLogKindDjiFlutterPlugin,
                  //   );
                  // });

                  // _vlcController?.initialize().then((_) {
                  //   _vlcController?.play();
                  // });

                  // _vpController =
                  //     VP.VideoPlayerController.file(File(outputPath))
                  //       ..initialize().then((_) {
                  //         // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
                  //         setState(() {
                  //           developer.log(
                  //             'Video Player initialized',
                  //             name: kLogKindDjiFlutterPlugin,
                  //           );

                  //           _vpController?.play().then((_) {
                  //             developer.log(
                  //               'Video Player: play',
                  //               name: kLogKindDjiFlutterPlugin,
                  //             );
                  //           }).onError((error, stackTrace) {
                  //             developer.log(
                  //               'Video Player: error',
                  //               error: error,
                  //               name: kLogKindDjiFlutterPlugin,
                  //             );
                  //           });
                  //         });
                  //       }).onError((error, stackTrace) {
                  //         developer.log(
                  //           'Video Player Initialize: error',
                  //           error: error,
                  //           name: kLogKindDjiFlutterPlugin,
                  //         );
                  //       });
                });
              }

              // Start the video feed
              await Dji.videoFeedStart();
              // await Future.delayed(const Duration(seconds: 2));

              // setState(() {
              //     _vlcController ??= VlcPlayerController.file(
              //       File(outputPipe),
              //       // _vlcController = VlcPlayerController.network(
              //       // 'udp://@0.0.0.0:1337',
              //       // _vlcController = VlcPlayerController.network(
              //       // 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
              //       autoInitialize: true,
              //       autoPlay: true,
              //       hwAcc: HwAcc.disabled,
              //       options: VlcPlayerOptions(
              //         video: VlcVideoOptions(
              //           [
              //             VlcVideoOptions.dropLateFrames(true),
              //             VlcVideoOptions.skipFrames(true),
              //           ],
              //         ),
              //         advanced: VlcAdvancedOptions([
              //           VlcAdvancedOptions.networkCaching(0),
              //           VlcAdvancedOptions.liveCaching(0),
              //           VlcAdvancedOptions.clockSynchronization(0),
              //         ]),
              //         sout: VlcStreamOutputOptions([
              //           VlcStreamOutputOptions.soutMuxCaching(0),
              //         ]),
              //         extras: [
              //           // '--start-time 2',
              //           // '-sout-keep',
              //           // '--ttl 60',
              //           // '--rtsp-tcp',
              //         ],
              //       ),
              //       onInit: () async {
              //         developer.log(
              //           'VLC Player initialized',
              //           name: kLogKindDjiFlutterPlugin,
              //         );

              //         // await _vlcController?.setMediaFromFile(
              //         //   File(outputPipe),
              //         //   autoPlay: true,
              //         //   hwAcc: HwAcc.auto,
              //         // );

              //         // developer.log(
              //         //   'VLC Player isSeekable: ${await _vlcController?.isSeekable()}',
              //         //   name: kLogKindDjiFlutterPlugin,
              //         // );

              //         // await _vlcController?.seekTo(
              //         //   const Duration(
              //         //     seconds: 3,
              //         //   ),
              //         // );

              //         // await Dji.videoFeedStart();
              //         // await Future.delayed(const Duration(seconds: 3));
              //         // await _vlcController?.play();
              //       },
              //     );
              //   });

              // if (statistics.getTime() > 1000 &&
              //     _nativeVideoViewController?.videoFile == null) {
              //   setState(() {
              //     _nativeVideoViewController
              //         ?.setVideoSource(
              //       outputPipe,
              //       // 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_20MB.mp4',
              //       sourceType: VideoSourceType.file,
              //       requestAudioFocus: false,
              //     )
              //         .then((_) {
              //       // _nativeVideoViewController?.play();
              //     });
              //   });
              // }

              // if (statistics.getVideoFrameNumber() > 1 &&
              //     _vpController != null) {
              //   developer.log(
              //     'FFmpegKit.executeAsync - starting Video Player',
              //     name: kLogKindDjiFlutterPlugin,
              //   );

              //   // Play the video player
              //   _vpController?.play();
              // }
            },
          );

          // Initializing the Video Player
          // _vpController = VP.VideoPlayerController.file(File(outputPipe));
          // _vpController = VP.VideoPlayerController.network(
          //   'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          // );

          // try {
          //   await _vpController?.initialize();
          //   developer.log(
          //     'Video Player initialized',
          //     name: kLogKindDjiFlutterPlugin,
          //   );
          // } catch (e) {
          //   developer.log(
          //     'Video Player initialization failed: ${e.toString()}',
          //     name: kLogKindDjiFlutterPlugin,
          //   );
          // }

          // _vpController?.play();

          // _vlcPlayer?.open(
          //   VLC.Media.file(
          //     File(outputPipe),
          //     startTime: const Duration(seconds: 5),
          //   ),
          //   autoStart: true,
          // );

          // FFmpegKit.execute(
          //   // '-y -flags2 showall -f h264 -err_detect ignore_err -i $videoFeedPath -f mp4 -movflags frag_keyframe+empty_moov $outputPipe',
          //   '-y -flags2 showall -f h264 -err_detect ignore_err -i $videoFeedPath -f mp4 -movflags frag_keyframe+empty_moov $outputPipe',
          // );
        });
      });
    } on PlatformException catch (e) {
      developer.log(
        'Video Feed Start PlatformException Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    } catch (e) {
      developer.log(
        'Video Feed Start Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    }
  }

  Future<void> _videoFeedStop() async {
    try {
      developer.log(
        'Video Feed Stop requested',
        name: kLogKindDjiFlutterPlugin,
      );
      // Stop the video feed
      await Dji.videoFeedStop();
      _videoFeedSink?.close();
      _vlcController?.stop();
      _vlcController?.dispose();
      _vlcController = null;
      // _vlcPlayer?.stop();
      // _vpController?.pause();
      // _nativeVideoViewController?.stop();

    } catch (e) {
      developer.log(
        'Video Feed Stop Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('DJI Flutter Plugin Example'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.2,
              color: Colors.black54,
              child: Stack(children: [
                // _vpController?.value.isInitialized == true
                //     ? VP.VideoPlayer(_vpController!)
                //     : Container(),

                _vlcController != null
                    ? VlcPlayer(
                        controller: _vlcController!,
                        aspectRatio: MediaQuery.of(context).size.width /
                            (MediaQuery.of(context).size.height * 0.2),
                      )
                    : Container(),

                // VLC.Video(
                //   player: _vlcPlayer,
                //   width: MediaQuery.of(context).size.width,
                //   height: MediaQuery.of(context).size.height * 0.2,
                //   // volumeThumbColor: Colors.blue,
                //   // volumeActiveColor: Colors.blue,
                //   // showControls: true,
                // )

                // NativeVideoView(
                //   keepAspectRatio: false,
                //   showMediaController: false,
                //   enableVolumeControl: false,
                //   onCreated: (controller) {
                //     _nativeVideoViewController = controller;
                //   },
                //   onPrepared: (controller, info) {
                //     debugPrint('NativeVideoView: Video prepared');
                //     // controller.play();
                //   },
                //   onError: (controller, what, extra, message) {
                //     debugPrint(
                //         'NativeVideoView: Player Error ($what | $extra | $message)');
                //   },
                //   onCompletion: (controller) {
                //     debugPrint('NativeVideoView: Video completed');
                //   },
                // ),
              ]),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: kSpacer, vertical: kSpacer * 0.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              key: const Key('registerAppButton'),
                              child: const Text('Register App'),
                              onPressed: () async {
                                await _registerApp();
                              },
                            ),
                            ElevatedButton(
                              key: const Key('connectDroneButton'),
                              child: const Text('Connect'),
                              onPressed: () async {
                                await _connectDrone();
                              },
                            ),
                            ElevatedButton(
                              key: const Key('delegateButton'),
                              child: const Text('Delegate'),
                              onPressed: () async {
                                await _delegateDrone();
                              },
                            ),
                            ElevatedButton(
                              key: const Key('takeOffDroneButton'),
                              child: const Text('Take Off'),
                              onPressed: () async {
                                await _takeOff();
                              },
                            ),
                            ElevatedButton(
                              key: const Key('landDroneButton'),
                              child: const Text('Land'),
                              onPressed: () async {
                                await _land();
                              },
                            ),
                            // ElevatedButton(
                            //   key: const Key('timelineDroneButton'),
                            //   child: const Text('Timeline'),
                            //   onPressed: () async {
                            //     await _timeline();
                            //   },
                            // ),
                            ElevatedButton(
                              key: const Key('start'),
                              child: const Text('Start'),
                              onPressed: () async {
                                await _start();
                              },
                            ),
                            ElevatedButton(
                              key: const Key('getMediaList'),
                              child: const Text('getMediaList'),
                              onPressed: () async {
                                await _getMediaList();
                              },
                            ),
                            ElevatedButton(
                              key: const Key('download'),
                              child: const Text('Download'),
                              onPressed: () async {
                                await _download();
                              },
                            ),
                            ElevatedButton(
                              key: const Key('delete'),
                              child: const Text('Delete'),
                              onPressed: () async {
                                await _delete();
                              },
                            ),
                            ElevatedButton(
                              key: const Key('startVideoFeed'),
                              child: const Text('Start Video Feed'),
                              onPressed: () async {
                                await _videoFeedStart();
                              },
                            ),
                            ElevatedButton(
                              key: const Key('stopVideoFeed'),
                              child: const Text('Stop Video Feed'),
                              onPressed: () async {
                                await _videoFeedStop();
                              },
                            ),
                            // ElevatedButton(
                            //   key: const Key('disconnectDroneButton'),
                            //   child: const Text('Disconnect'),
                            //   onPressed: () async {
                            //     await _disconnectDrone();
                            //   },
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(kSpacer),
                        child: Column(
                          children: [
                            DronePropertyRow(
                              label: 'Running on',
                              value: _platformVersion,
                            ),
                            DronePropertyRow(
                              label: 'Status',
                              value: _droneStatus,
                            ),
                            DronePropertyRow(
                              label: 'Drone Battery',
                              value: _droneBatteryPercent + '%',
                            ),
                            DronePropertyRow(
                              label: 'Altitude',
                              value: _droneAltitude,
                            ),
                            DronePropertyRow(
                              label: 'Latitude',
                              value: _droneLatitude,
                            ),
                            DronePropertyRow(
                              label: 'Longitude',
                              value: _droneLongitude,
                            ),
                            DronePropertyRow(
                              label: 'Speed',
                              value: _droneSpeed,
                            ),
                            DronePropertyRow(
                              label: 'Roll',
                              value: _droneRoll,
                            ),
                            DronePropertyRow(
                              label: 'Pitch',
                              value: _dronePitch,
                            ),
                            DronePropertyRow(
                              label: 'Yaw',
                              value: _droneYaw,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DronePropertyRow extends StatelessWidget {
  const DronePropertyRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyText2,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ],
    );
  }
}
