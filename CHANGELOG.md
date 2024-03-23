# Changelog

## 1.0.13
- Upgraded DJI Mobile SDK Android to v4.17.

## 1.0.12
- Additional updates to support Android 12 and 13.

## 1.0.11
- Updates to support Android 13.

## 1.0.10
- Upgraded Android Compile SDK version and Target to 33.

## 1.0.9
- Upgraded DJI SDKs to latest versions on Android.

## 1.0.8
- Fixed an issue with Drone Status being an empty-string on Android.

## 1.0.7
- Added drone status error description property.

## 1.0.6
- Fixed additional issues with Azimuth calculation.

## 1.0.5
- Fixed Azimuth calculation.

## 1.0.4
- Fixed gimbal pitch computed angle.

## 1.0.3
- Fixed vector to location coordinates calculations.
- Updated tests.

## 1.0.2
- Added some missing Android configuration instructions to the Readme.

## 1.0.1
- Updated the Readme with the possible String drone.status property values.

## 1.0.0
- Upgraded packages.
- Tested with Flutter 3.3.

## 1.0.0-dev.23
- Added mobile-remote-controller methods (relevant when the drone is connected via Wifi).
- Added virtual-stick methods (relevant when the drone is connected via the physical remote controller).
- Added gimbal rotate (pitch) method.
- Added start/stop video recording methods.

## 1.0.0-dev.22
- Android Example fine-tunings.

## 1.0.0-dev.21
- Fixed an issue with proper disposal (close) of the DJI Previewer.
- Adjusted the HLS properties and VLC Player timing for better performance.

## 1.0.0-dev.20
- Updated readme.

## 1.0.0-dev.19
- Bumbed version to .19 due to a minor publishing issue (no code change).

## 1.0.0-dev.18
- Finalized Android platform video feed updates.
- Updated both Android and iOS to send rawvideo YUV420p frames (instead of the raw H264) in order to achieve higher quality.

## 1.0.0-dev.17
- Added methods to start and stop the live video feed (a.k.a "preview") of the DJI SDK. Once started, the DJI SDK produces a raw h264 byte-stream from the camera of the drone (Primary Physical Source) and `sendVideo()` method is triggered on the Flutter side, receiving a stream of data (bytes).
- Update the example accordingly, and used FFmpeg-kit plugin to pipe the video stream in real-time and output an HLS (or MP4) that can be video in near-real-time by the Flutter VLC Video Player.
- Upgraded Pigeon to latest (v3.1.6)

## 1.0.0-dev.16
- Updated readme with the latest new methods examples.
- droneHomeLocation usage cleanup.

## 1.0.0-dev.15
- Fixed save path bug on Android.

## 1.0.0-dev.14
- Completed support for downloading and deleting media files on Android.

## 1.0.0-dev.13
- Finalized ability to download and delete specific media files (iOS only for now).
- Including saving the downloaded media to the device gallery (this will be changed in the future to be done via the Example Flutter app and not natively).
- Fixed the conversion calculations of the Flight Vector Waypoints to Location Waypoints.
- Updated tests.
- Started adding the matching Android methods (work in progress).
- Enhanced examples.
- Cleanup.

## 1.0.0-dev.12
- Added the ability to download media.
- Currently supported only on iOS, and only downloads the latest media file.
- Work in progress...

## 1.0.0-dev.11
- Upgraded to DJI Mobile SDK IOS 4.16 and DJI Mobile SDK Android 4.16.1.
## 1.0.0-dev.10
- Bug fixes.

## 1.0.0-dev.9
- Updated documentation.
- Changed several static properties to methods in the Dji class.

## 1.0.0-dev.8
- Added Download & Delete media files methods for both iOS and Android.

## 1.0.0-dev.7
- Improved readme in regards to Android configuration.

## 1.0.0-dev.6
- Improved readme.
- Added CodeMagic CI/CD badge.

## 1.0.0-dev.5
- Enhanced iOS setup Readme.
- Fixed a type mismatch bug in the iOS native part.

## 1.0.0-dev.4
- Updated description and corrected messages.dart code formatting.

## 1.0.0-dev.3
- Updated Example Tab in pub.dev.

## 1.0.0-dev.2
- Updated /example README.md

## 1.0.0-dev.1
- Initial in-development release.

