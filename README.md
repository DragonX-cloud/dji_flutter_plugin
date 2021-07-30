# dji
## A Flutter plugin for DJI SDK.
This open source project intends to bring the DJI SDK functionalities into Flutter.

**// WORK IN PROGRESS**

## Plugin Creation

This project was created by the Flutter plugin template using:
```
flutter create --org cloud.dragonx.plugin.flutter --template=plugin --platforms=ios -i swift dji
```

[ ! ] Important Note
Make sure you `cd example` and run `flutter build ios --no-codesign` before starting to change anything in Xcode or Flutter.
Otherwise, the plugin might not get built properly later on (I don't know why though).

## Pigeon
This plugin uses Pigeon:
https://pub.dev/packages/pigeon

To re-generate the Pigeon interfaces, execute:
flutter pub run pigeon \
  --input pigeons/messages.dart \
  --dart_out lib/messages.dart \
  --objc_header_out ios/Classes/messages.h \
  --objc_source_out ios/Classes/messages.m \
  --objc_prefix FLT \
//  --java_out android/src/main/java/cloud/dragonx/dji/Messages.java \
//  --java_package "cloud.dragonx.plugin.flutter.dji"

### Pigeon Swift Example
https://github.com/DJI-Mobile-SDK-Tutorials/iOS-ImportAndActivateSDKInXcode-Swift

## Configuring the iOS Xcode Project
https://developer.dji.com/document/76942407-070b-4542-8042-204cfb169168

Click the "info" tab (in between the Resource Tags and the Build Settings).
Under the "Custom iOS Target Properties" section - right click on the last row and choose "Add Row" and add the following:

Add "Supported external accessory protocols" with 3 items:
- Item0 = com.dji.common
- Item1 = com.dji.protocol
- Item2 = com.dji.video

Add the "App Transport Security Settings" key, with "Allow Arbitrary Loads" of values YES.

Create a DJISDKAppKey key in the info.plist file and paste the App Key string into its string value (right click on any of the existing rows or below them and add a new row).
FDJI Example API Key for package ID cloud.dragonx.plugin.flutter.dji = e6775a00cf003fca9680d32c

Add the key `NSBluetoothAlwaysUsageDescription` to the Info.plist with a description explaining that the DJI Drone requires bluetooth connection.

Note:
Don't forget to run `pod install` from the ./ios folder of your project, and verify that you're able to compile your project via Xcode (before compiling via Flutter).