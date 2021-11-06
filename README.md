# dji
## A Flutter plugin for DJI SDK.
This open source project intends to bring the DJI SDK functionalities into Flutter.

**// WORK IN PROGRESS**

## Plugin Creation
This project was created by the Flutter plugin template using:
```
flutter create --org cloud.dragonx.plugin.flutter --template=plugin --platforms=ios -i swift dji
```
Android was added later on using:
```
flutter create --org cloud.dragonx.plugin.flutter --template=plugin --platforms=android .
```
Note: The folder name is "dji", just like we specified in the original flutter create command for iOS (otherwise it will cause different package names and class paths).
Also, when not specifying "-a java" - the Android project is Kotlin.
We're using iOS Swift and Android Kotlin (The Android project is Kotlin, although the DJI SDK is in Java).

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
  --java_out android/src/main/java/cloud/dragonx/plugin/flutter/dji/Messages.java \
  --java_package "cloud.dragonx.plugin.flutter.dji"

### Pigeon Swift Example
https://github.com/DJI-Mobile-SDK-Tutorials/iOS-ImportAndActivateSDKInXcode-Swift

### Pigeon Android Kotlin Example
https://github.com/gaaclarke/pigeon_plugin_example

Example how to use FlutterAPI (trigger a function from the native platform side):
https://github.com/glassmonkey/flutter_wifi/blob/master/android/app/src/main/kotlin/nagano/shunsuke/flutter_wifi_sample/WifiApi.kt

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

## Configuring the Android Studio Kotlin project
https://github.com/DJI-Mobile-SDK-Tutorials/Android-ImportAndActivateSDKInAndroidStudio

DJI Android Sample App:
https://github.com/dji-sdk/Mobile-SDK-Android/tree/master/Sample%20Code

Another useful demo app - Android Simulator Demo:
https://github.com/DJI-Mobile-SDK-Tutorials/Android-SimulatorDemo/blob/master/DJISimulatorDemo/app/src/main/java/com/dji/simulatorDemo/MainActivity.java

The DJI Tutorial can be found here below, but please note you must rely on the above Github Repo as reference, because many of the code examples inside this tutorial are outdated:
https://developer.dji.com/mobile-sdk/documentation/application-development-workflow/workflow-integrate.html#import-maven-dependency

If you're trying to run the DJI sample, then note that in MainActivity.kt:
- Need to remove "import android.R"

In build.gradle:
- Had to set the Target SDK to 30 (and not 31, as it caused issues with the Manifest merge)
- [ ! ] IMPORTANT: For DJI SDK to work properly the minSDK must be set to 19 (otherwise the helper.install doesn't work).
- Due to the minSDK 19 - MultiDex MUST be enabled.

## Notes in regards to DJI SDK
- Decided not to implement the "Bridge App" support, because turned out that - for debugging / development purposes - it is much easier to simply connect to the drone's Wifi, and let it connect using it (instead of using the Remote Controller).

[ ! ] Important Note
A bug in DJI's SDK in regards to Wifi Connection:
If you're developing / debugging, and your phone is connected to the Drone's Wifi - it means your mobile device does NOT have any internet connection.
Therefore, the Registration won't work.
However, due to a bug in the SDK - the appRegisteredWithError() responds with a "success", although it actually fails.

The solution is to first make sure you're disconnected from the Drone's Wifi - and let your App perform the Registration successfully.
And only after it has been registered - connect your mobile device to the Drone's Wifi, and execute the startConnectionToProduct()

Hint was taken from this issue on Github:
https://github.com/dji-sdk/Mobile-SDK-Android/issues/232

[ ! ] Important Note
Before using any DJI SDK methods - you must execute:
```
Helper.install(this)
```
Usually this should be placed in your main application .kt file:
For example:
```
public class MyApplication : Application() {
    override fun attachBaseContext(paramContext: Context?) {
        super.attachBaseContext(paramContext)
        Helper.install(this)
    }
}
```

## DJI References
Useful tutorial: https://www.tooploox.com/blog/automated-drone-missions-on-ios

## Debugging Android over Wifi
Find your device IP Address through the Android > Settings > wifi, and then run the following from your Desktop terminal:
```
adb tcpip 4455
adb connect {{your-android-ip}}:4455
```
