import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:io';

import 'package:dji/flight.dart';
import 'package:dji/messages.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:dji/dji.dart';

import 'constants.dart';

import 'package:path_provider/path_provider.dart';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';

import 'package:flutter_vlc_player/flutter_vlc_player.dart';

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

              // This initial waypoint is important, the DJI SDK ignores the cornerRadiusInMeters of the first waypoint (and the turn would not be "round").
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

        // final String outputPath = directory.path + '/output_test.ts';
        // final File outputFile = File(outputPath);
        // if (await outputFile.exists() == true) {
        //   outputFile.delete();
        // }

        const String exampleAssetPath = 'videos/example.mov';

        ByteData data = await rootBundle.load(exampleAssetPath);
        String exampleStreamPath = directory.path + '/example_stream.mov';
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(exampleStreamPath).writeAsBytes(bytes);

        final String videoFeedPath = inputPipe;
        _videoFeedFile = File(videoFeedPath);

        developer.log(
          'Video Feed Start - video feed path: $videoFeedPath',
          name: kLogKindDjiFlutterPlugin,
        );

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

          _videoFeedSink = _videoFeedFile?.openWrite();

          setState(() {
            _vlcController ??= VlcPlayerController.file(
              File(outputPipe),
              // _vlcController = VlcPlayerController.network(
              // 'udp://@0.0.0.0:1337',
              // _vlcController = VlcPlayerController.network(
              // 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
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
                  VlcAdvancedOptions.fileCaching(0),
                  VlcAdvancedOptions.networkCaching(0),
                  VlcAdvancedOptions.liveCaching(0),
                  VlcAdvancedOptions.clockSynchronization(0),
                ]),
                sout: VlcStreamOutputOptions([
                  VlcStreamOutputOptions.soutMuxCaching(0),
                ]),
                extras: [
                  // '--key-faster 10',
                  // '--start-time 2',
                  // '-sout-keep',
                  // '--ttl 1',
                  // '--rtsp-tcp',
                ],
              ),
            );
          });

          _vlcController?.addOnInitListener(() async {
            developer.log(
              'VLC Player: addOnInitListener - initialized',
              name: kLogKindDjiFlutterPlugin,
            );
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
            // '-y -re -err_detect ignore_err -f mov -i $exampleStreamPath -fflags discardcorrupt -fflags nobuffer -avioflags direct -flags low_delay -s 640x360 -r 15 -f hls -hls_time 0 $outputPipe',
            // '-y -re -err_detect ignore_err -f mov -i $exampleStreamPath -fflags discardcorrupt -fflags nobuffer -avioflags direct -flags low_delay -s 640x360 -r 15 -f hls -hls_time 0 udp://localhost:1337',
            // '-y -err_detect ignore_err -f mov -i $exampleStreamPath -f mpegts -s 640x360 -r 15 $outputPipe',
            // '-y -err_detect ignore_err -flags2 showall -f h264 -i $inputPipe -f mpegts -s 640x360 -r 15 $outputPipe',
            // '-y -re -err_detect ignore_err -flags2 showall -f h264 -i $inputPipe -fflags discardcorrupt -fflags nobuffer -avioflags direct -flags low_delay -s 640x360 -r 15 -f hls -hls_time 0 $outputPipe',
            // '-y -flags2 showall -f h264 -i $inputPipe -s 640x360 -r 10 -f hls -hls_time 0 $outputPipe',
            // '-y -flags2 showall -f h264 -i $inputPipe -s 640x360 -r 15 -chunk_duration 0 -max_delay 0 -f hls -hls_time 500ms -hls_list_size 12 -hls_allow_cache 1 -hls_flags split_by_time $outputPipe',
            // '-y -flags2 showall -f h264 -i $inputPipe -s 640x360 -vf "fps=15" -c:v libx264 -f hls $outputPipe',
            // '-y -flags2 showall -f h264 -i $inputPipe -fflags discardcorrupt -fflags nobuffer -avioflags direct -flags low_delay -f hls -hls_allow_cache 0 -hls_time 200ms -hls_list_size 3 -max_delay 0 -s 640x360 -r 15 -vf "fps=15" -g 15 -b:v 10k -maxrate 10k -bufsize 10k $outputPipe',
            // '-y -flags2 showall -f h264 -i $inputPipe -f mp4 -movflags frag_keyframe+empty_moov -s 640x360 -r 15 -vf "fps=15" -g 15 -b:v 10k -maxrate 10k -bufsize 10k $outputPipe',

            '-y -avioflags direct -max_delay 0 -flags2 showall -f h264 -i $inputPipe -fflags nobuffer+discardcorrupt+noparse+nofillin+ignidx+flush_packets+fastseek -avioflags direct -max_delay 0 -flags low_delay -f hls -hls_time 0 -hls_allow_cache 0 $outputPipe',
            // '-y -avioflags direct -max_delay 0 -flags2 showall -f h264 -i $inputPipe -fflags nobuffer+discardcorrupt+noparse+nofillin+ignidx+flush_packets+fastseek -avioflags direct -max_delay 0 -f mp4 -movflags frag_keyframe+empty_moov $outputPipe',
            // '-y -avioflags direct -max_delay 0 -flags2 showall -f h264 -i $inputPipe -fflags nobuffer+discardcorrupt+noparse+nofillin+ignidx+flush_packets+fastseek -avioflags direct -max_delay 0 -f mpegts $outputPipe',
            (session) async {
              _ffmpegKitSessionId = session.getSessionId();

              developer.log(
                'FFmpegKit sessionId: $_ffmpegKitSessionId',
                name: kLogKindDjiFlutterPlugin,
              );
            },
            (log) {
              // if (log.getLevel() < 32) {
              // developer.log(
              //   'FFmpegKit logs: ${log.getMessage()} (level ${log.getLevel()})',
              //   name: kLogKindDjiFlutterPlugin,
              // );
              // }
            },
            (statistics) async {
              // developer.log(
              //   'FFmpegKit statistics - frame: ${statistics.getVideoFrameNumber()}, time: ${statistics.getTime()}, bitrate: ${statistics.getBitrate()}',
              //   name: kLogKindDjiFlutterPlugin,
              // );

              if (statistics.getTime() >= 1 &&
                  await _vlcController?.isPlaying() == false) {
                // if (statistics.getVideoFrameNumber() == 1) {
                developer.log(
                  'VLC Player: play',
                  name: kLogKindDjiFlutterPlugin,
                );

                setState(() {
                  _vlcController?.play();
                });
              }
            },
          );

          // Start the video feed
          await Dji.videoFeedStart();
          // await Future.delayed(const Duration(milliseconds: 4000));
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
              child: _vlcController != null
                  ? VlcPlayer(
                      controller: _vlcController!,
                      aspectRatio: MediaQuery.of(context).size.width /
                          (MediaQuery.of(context).size.height * 0.2),
                    )
                  : Container(),
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
