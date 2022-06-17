import 'dart:io';

import 'package:dji_example/constants.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'dart:developer' as developer;

class VideoFeed {
  VideoFeed({
    this.url,
  });

  String? url;

  int? _ffmpegKitSessionId;
  File? _videoFeedFile;

  // final String url;

  static Future<void> start(Map<dynamic, dynamic> args) async {
    FFmpegKitConfig.registerNewFFmpegPipe().then((inputPipe) async {
      if (inputPipe == null) {
        developer.log(
          'Video Feed Start failed - no Input Pipe',
          name: kLogKindDjiFlutterPluginExample,
        );

        return;
      }

      // final String videoFeedPath = inputPipe;
      // _videoFeedFile = File(videoFeedPath);

      // FFmpegKitConfig.registerNewFFmpegPipe().then((outputPipe) async {
      //   if (outputPipe == null) {
      //     developer.log(
      //       'Video Feed Start failed - no Output Pipe',
      //       name: kLogKindDjiFlutterPluginExample,
      //     );

      //     return;
      //   }

      //   // We must close the output pipe here, otherwise the FFMPEG convertion won't start.
      //   FFmpegKitConfig.closeFFmpegPipe(outputPipe);

      //   // Opening the video feed file (input pipe) for writing.
      //   _videoFeedSink = _videoFeedFile?.openWrite();

      //   // Initializing the VLC Video Player.
      //   setState(() {
      //     _vlcController ??= VlcPlayerController.file(
      //       File(outputPipe),
      //       autoInitialize: true,
      //       autoPlay: false,
      //       hwAcc: HwAcc.auto,
      //       options: VlcPlayerOptions(
      //         video: VlcVideoOptions(
      //           [
      //             VlcVideoOptions.dropLateFrames(true),
      //             VlcVideoOptions.skipFrames(true),
      //           ],
      //         ),
      //         advanced: VlcAdvancedOptions([
      //           VlcAdvancedOptions.fileCaching(0),
      //           VlcAdvancedOptions.networkCaching(0),
      //           VlcAdvancedOptions.liveCaching(0),
      //           VlcAdvancedOptions.clockSynchronization(0),
      //         ]),
      //         sout: VlcStreamOutputOptions([
      //           VlcStreamOutputOptions.soutMuxCaching(0),
      //         ]),
      //         extras: [],
      //       ),
      //     );
      //   });

      //   // _vlcController?.addOnInitListener(() async {
      //   //   developer.log(
      //   //     'VLC Player: addOnInitListener - initialized',
      //   //     name: kLogKindDjiFlutterPluginExample,
      //   //   );
      //   // });

      //   // Executing the FFMPEG convertion (from the native DJI SDK H264 Raw Byte Stream to HLS for minimal latency)
      //   await FFmpegKit.executeAsync(
      //     // https://ffmpeg.org/ffmpeg-formats.html
      //     // Using "-re" causes the input to stream-in slower, but we want the convertion to be done ASAP, so we don't use it.
      //     '-y -avioflags direct -max_delay 0 -flags2 showall -f h264 -i $inputPipe -fflags nobuffer+discardcorrupt+noparse+nofillin+ignidx+flush_packets+fastseek -avioflags direct -max_delay 0 -flags low_delay -f hls -hls_time 0 -hls_allow_cache 0 $outputPipe',
      //     // MP4 works too, but it's not the best format for streaming, as it causes additional latency. Example with MP4:
      //     // '-y -avioflags direct -max_delay 0 -flags2 showall -f h264 -i $inputPipe -fflags nobuffer+discardcorrupt+noparse+nofillin+ignidx+flush_packets+fastseek -avioflags direct -max_delay 0 -f mp4 -movflags frag_keyframe+empty_moov $outputPipe',
      //     (session) async {
      //       _ffmpegKitSessionId = session.getSessionId();

      //       developer.log(
      //         'FFmpegKit sessionId: $_ffmpegKitSessionId',
      //         name: kLogKindDjiFlutterPluginExample,
      //       );
      //     },
      //     (log) {
      //       // The logs here are disabled because they cause additional latency for some reason.
      //       // if (log.getLevel() < 32) {
      //       //   developer.log(
      //       //     'FFmpegKit logs: ${log.getMessage()} (level ${log.getLevel()})',
      //       //     name: kLogKindDjiFlutterPluginExample,
      //       //   );
      //       // }
      //     },
      //     (statistics) async {
      //       // The logs here are disabled because they cause additional latency for some reason.
      //       // developer.log(
      //       //   'FFmpegKit statistics - frame: ${statistics.getVideoFrameNumber()}, time: ${statistics.getTime()}, bitrate: ${statistics.getBitrate()}',
      //       //   name: kLogKindDjiFlutterPluginExample,
      //       // );

      //       // Using .getVideoFrameNumber == 1 causes the video to start too soon. Therefore we're using .getTime() >= 1 and checking whether the video is already playing.
      //       if (statistics.getTime() >= 1 &&
      //           await _vlcController?.isPlaying() == false) {
      //         developer.log(
      //           'VLC Player: play',
      //           name: kLogKindDjiFlutterPluginExample,
      //         );

      //         setState(() {
      //           _vlcController?.play();
      //         });
      //       }
      //     },
      //   );
      // });
    });
  }
}
