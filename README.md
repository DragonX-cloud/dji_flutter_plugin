# dji
[![Codemagic build status](https://api.codemagic.io/apps/61a1e99d95aace19d105564c/61a1e99d95aace19d105564b/status_badge.svg)](https://codemagic.io/apps/61a1e99d95aace19d105564c/61a1e99d95aace19d105564b/latest_build)
## A FLUTTER PLUGIN FOR DJI SDK
This open source project intends to bring the DJI SDK functionalities into Flutter.

We strongly advice to first read at least the DJI Hardware Introduction:  
https://developer.dji.com/document/52b7f3b9-a773-47b3-b9e5-71c7a3190736  
And the DJI Mobile SDK Introduction:  
https://developer.dji.com/document/4cd08995-3952-4db6-ab6e-bc3a754da153  
To get familiar with the basic terminology and concepts.

The plugin supports the following features:
- Register
- Connect / Disconnect
- Takeoff
- Land
- Start Timeline:
	- Takeoff
	- Land
	- Take a picture
	- Start/Stop video
	- Waypoints Mission
- Mobile Remote Controller (Wifi)
- Virtual Stick (Physical Remote)
- Gimbal Rotate (Pitch)
- Get Media Files List
- Download Media File by Index
- Delete Media File by Index
- Live Video Feed (rawvideo YUV420p)
- Start/Stop Video Recording

## SETUP
Before you start using the DJI Flutter plugin, you must first perform some initial setup and configurations as required by DJI SDK.

### Getting DJI Developer Credentials
In order to use DJI SDK, you need to become a DJI Developer:
https://developer.dji.com/

Once registered and signed-in, you need to create two new apps - one for Android and one for iOS.  
Make sure you fill-in your correct App package-name as defined when you created your Flutter project.

Once your Apps are registered on DJI Developer Portal, you have an "App Key" for each one.
This App Key should be included in your Android Manifest XML and iOS info.plist as described later on.

You may search the Github /example folder to locate the App Keys that were used in the example project:  
`cloud.dragonx.plugin.flutter.djiExample` on iOS is using `b5245cf16f4b43ed90d436ba`  
`cloud.dragonx.plugin.flutter.djiExample` on Android is using `23acf68f822be3f065e6f538`

##### Note
The best way to create a Flutter project with your desired package-name is by command line and the --org argument:  
```
mkdir yourAppNAme
cd ./yourAppName
flutter create --org com.yourdomain --project-name yourAppName .
```
(notice the "." at the end)  
https://flutteragency.com/create-a-new-project-in-flutter/

**For a tip in regards to package names - please [read this](#a-tip-in-regards-to-package-names).**

### Configuring the DJI SDK on your Flutter iOS Project
The DJI SDK is automatically added by the plugin.  
However, we still need to configure a few parameters directly on the iOS project via Xcode.
##### 1. Configure Build Settings
- Open your Flutter iOS Workspace in Xcode.  
- Click the "Runner" label on the top-left of the left Sidebar.
- Then, make sure you are on Targets > Runner (middle Sidebar).
- Click the "info" tab (in between the Resource Tags and the Build Settings).  
- Under the "Custom iOS Target Properties" section - right click on the last row and choose "Add Row" and add the following:
  - Add "Supported external accessory protocols" with 3 items:
    - Item0 = com.dji.common
    - Item1 = com.dji.protocol
    - Item2 = com.dji.video
  - Add the "App Transport Security Settings" key > click the "+" and choose "Allow Arbitrary Loads" and change the value to "YES".

##### 2. Update the info.plist
- **Create a `DJISDKAppKey` key in the info.plist file and paste the App Key string into its string value (right click on any of the existing rows or below them and add a new row).**
- Add the key `NSBluetoothAlwaysUsageDescription` to the Info.plist with a description explaining that the DJI Drone requires bluetooth connection.

##### 3. Sign your App and run it first from within Xcode
- Before you try to run your app from Flutter, you better try to build it from within Xcode.
- You also need to first make sure that you sign your app via Xcode:
- Click the "Runner" label on the top-left of the left Sidebar and then click the tab "Signing & Capabilities".
- Choose your Team (per your Apple developer account team) and choose your signing certificates (or simply check the Automatically manage signing checkbox).

**[ ! ] Important Note**
If you try to archive / build your App from Xcode or Flutter, and receive an error saying:
```
While building module 'DJISDK' imported from...
Encountered error while building for device.
```
It's most probably because the Architecture it was trying to build for was not arm64.
You can fix this by openining Xcode > and under the Build Settings tab > search for "Architectures", and change the value there to `arm64` (instead of the "Standard Architectures" that is the default there).

##### Note
Full details of setting up the DJI SDK for iOS can be found here:  
https://developer.dji.com/document/76942407-070b-4542-8042-204cfb169168  
### Configuring the DJI SDK on your Flutter Android (Kotlin) Project
The DJI SDK is automatically added by the plugin.  
However, we still need to configure a few parameters directly on the Android project via Android Studio.

> **[ ! ] Important Note**
> On Android - the DJI SDK cannot run the Simulator. 
> If you try to run it on the Android Emulator - it will launch and immediately crash.
> This is due to a DJI SDK limitation.
> In any case, in order to truly develop while being connected to the Drone, you must run the app on an actual device (for both iOS and Android).
##### 1. Upgrade to Kotlin 
Edit the `android/grade/wrapper/gradle-wrapper.properties` file, and update the last line to:
```
distributionUrl=https\://services.gradle.org/distributions/gradle-7.0.2-all.zip
```

Then, update the `buildScript` in the `android/build.gradle` file to:
```
buildscript {
    ext.kotlin_version = '1.7.0'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.2.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

Lastly, open the Project in Android Studio and let the Gradle sync.
Please note this "sync" might take several long minutes.

##### 2. Updated the Android Manifest XML
Below the <manifest> tag and above the <application> tag, add the following permissions: 
(you might not need all of these, but usually that's what's needed for full functionality of the DJI SDK) 
```
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="...">
  <!-- Permissions and features -->
  <uses-permission android:name="android.permission.BLUETOOTH" />
  <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
  <uses-permission android:name="android.permission.VIBRATE" />
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
  <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.READ_PHONE_STATE" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
  <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
  <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

  <uses-feature android:name="android.hardware.camera" />
  <uses-feature android:name="android.hardware.camera.autofocus" />
  <uses-feature
      android:name="android.hardware.usb.host"
      android:required="false" />
  <uses-feature
      android:name="android.hardware.usb.accessory"
      android:required="true" />
```

Below the `<application>` tag and above the `<activity>` tag, add the following and fill-in your Android DJI App Key:
```
<application
  ...
  android:usesCleartextTraffic="true">
  ...
  <!-- Start of DJI SDK -->
  <uses-library android:name="com.android.future.usb.accessory" />
  <uses-library android:name="org.apache.http.legacy" android:required="false" />
  <meta-data android:name="com.dji.sdk.API_KEY" android:value="{{your-dji-app-key}}" />
  <!-- End of DJI SDK -->
  
  <activity...
```

##### 3. Update android/app/build.gradle
Open the android/app/build.grade file and update the following:
- Set the compileSdkVersion to 33
- Set defaultConfig parameters with minSdkVersion 24 and targetSdkVersion 31.
Also, **add and make sure multiDexEnabled is set to TRUE**:
```
android {
    compileSdkVersion 33
    ...
    defaultConfig {
        ...
        minSdkVersion 24
        targetSdkVersion 31
        ...

        multiDexEnabled true
    }
}
```

- Below the `buildTypes` add the `packagingOptions` section to exclude the `rxjava.properties`:
```
packagingOptions {
  exclude 'META-INF/rxjava.properties'
}
```
- Under the dependencies section - include the following dependencies:
```
dependencies {
    ...
    implementation 'androidx.multidex:multidex:2.0.1'
    implementation 'androidx.core:core-ktx:1.6.0'
    implementation 'androidx.appcompat:appcompat:1.3.1'
    implementation 'com.google.android.material:material:1.4.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.1'
    implementation 'org.jetbrains.kotlinx:kotlinx-serialization-json:1.3.0'
}
```

##### 4. Validate gradle.properties
Open android/gradle.properties and validate that you have both these lines with value TRUE:
```
android.useAndroidX=true
android.enableJetifier=true
```
##### Note
Full details of setting up the DJI SDK for Android can be found here:  
https://developer.dji.com/mobile-sdk/documentation/application-development-workflow/workflow-integrate.html#android-studio-project-integration

If you wish to learn and experiment with the DJI SDK on Android - here are some useful links and tips.

DJI Android Sample App:  
https://github.com/dji-sdk/Mobile-SDK-Android/tree/master/Sample%20Code

Another useful demo app - Android Simulator Demo:  
https://github.com/DJI-Mobile-SDK-Tutorials/Android-SimulatorDemo/blob/master/DJISimulatorDemo/app/src/main/java/com/dji/simulatorDemo/MainActivity.java

The DJI Tutorial can be found here below, but please note you must rely on the above Github Repo as reference, because many of the code examples inside this tutorial are outdated:
https://developer.dji.com/mobile-sdk/documentation/application-development-workflow/workflow-integrate.html#import-maven-dependency

If you're trying to run the DJI sample, then note that in MainActivity.kt - Need to remove "import android.R".

### Preparing your Development Environment & Simulator
- Your DJI Drone should be connected by a USB to your computer.
- You should install the DJI Assistance > connect to the Drone > open and start the simulator.
- The remote control should be connected by cable to your development mobile device.
- The mobile device should be connected to the same Wifi as your computer.
	- For iOS Xcode - this should be sufficient to allow Xcode to install and debug your app on the mobile device.
	- For Android - use [these instructions](#debugging-android-over-wifi) to allow Wifi installation and debugging.

## USAGE
Once you have completed the above setup, you are ready to start using the DJI Flutter plugin in your Flutter code.

For general knowledge, the `Dji` class is using the `DjiHostApi` class to trigger methods on the "host platform" (the native part).
The `DjiFlutterApi` class is responsible for allowing the host to trigger methods on the Flutter side.

A full example can be found in the example/lib/example.dart file:  
https://github.com/DragonX-cloud/dji_flutter_plugin/blob/main/example/lib/example.dart

### Getting continuous updates of the Drone Status
We want the drone to to send us statuses.  
This is handled by the `DjiFlutterApi` class.

The `DjiFlutterApi.setStatus(Drone drone)` method is triggered by the native platform part every time there is an update to the Drone's state, location, angle, etc.
Currently, the Drone class has a String property `status` with a description of the state.
This will later on be changed to a DroneState class of its own, with an Enum code and a String description.

Currently, the possible `drone.status` strings are:
```
Registered
Connected
Disconnected
Delegated
Error
Mobile Remote
Mobile Remote Failed
Virtual Stick
Virtual Stick Failed
Gimbal Rotated
Gimbal Failed
Takeoff
Takeoff Failed
Land
Land Failed
Started
Start Failed
Got Media List
Media List Failed
Download Started (Once a download started - the drone.status changes to the actual percentage progress)
Downloaded
Download Failed
Deleted
Delete Failed
Video Started
Video Start Failed
Video Stopped
Video Stop Failed
Record Started
Record Start Failed
Record Stopped
Record Stop Failed
```

#### Extend your Widget with DjiFlutterApi
First, extend your Widget with DjiFlutterApi, define the drone properties, and override your initState() method with the `_initDroneState()` and `DjiFlutterApi.setup()` methods per your needs.
```
class _ExampleWidgetState extends State<ExampleWidget>
    implements DjiFlutterApi {
  String _platformVersion = 'Unknown';
  String _droneStatus = 'Disconnected';
  String _droneError = '';
  String _droneBatteryPercent = '0';
  String _droneAltitude = '0.0';
  String _droneLatitude = '0.0';
  String _droneLongitude = '0.0';
  String _droneSpeed = '0.0';
  String _droneRoll = '0.0';
  String _dronePitch = '0.0';
  String _droneYaw = '0.0';

  FlightLocation? droneHomeLocation;

  @override
  void initState() {
    super.initState();

    DjiFlutterApi.setup(this);

    ...
  }
  ...
```
#### setStatus
Once we defined our private properties that we wish to get from the Drone, let's override the `setStatus()` method.  
**The `setStatus()` method is triggered by the native host side of the plugin whenever the Drone status is changed.**

Example:
```
@override
void setStatus(Drone drone) async {
  setState(() {
    _droneStatus = drone.status ?? 'Disconnected';
    _droneError = drone.error ?? '';
    _droneAltitude = drone.altitude?.toStringAsFixed(2) ?? '0.0';
    _droneBatteryPercent = drone.batteryPercent?.toStringAsFixed(0) ?? '0';
    _droneLatitude = drone.latitude?.toStringAsFixed(7) ?? '0.0';
    _droneLongitude = drone.longitude?.toStringAsFixed(7) ?? '0.0';
    _droneSpeed = drone.speed?.toStringAsFixed(2) ?? '0.0';
    _droneRoll = drone.roll?.toStringAsFixed(3) ?? '0.0';
    _dronePitch = drone.pitch?.toStringAsFixed(3) ?? '0.0';
    _droneYaw = drone.yaw?.toStringAsFixed(3) ?? '0.0';
  });

  // Setting the inital drone location as the home location of the drone.
  if (droneHomeLocation == null &&
      drone.latitude != null &&
      drone.longitude != null &&
      drone.altitude != null) {
    droneHomeLocation = FlightLocation(
        latitude: drone.latitude!,
        longitude: drone.longitude!,
        altitude: drone.altitude!);
  }
}
```
Note that as soon as we get the first status from the Drone - we set the `droneHomeLocation` property.
This is simply useful for other parts of the Example project.

### Sending Commands to the Drone
The `Dji` class provides us with methods to connect and operate the Drone.

#### Dji.platformVersion
The `Dji.platformVersion` gets the host (native platform) version (e.g. The iOS or Android version).

Example:
```
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
```

#### Dji.registerApp
The `Dji.registerApp` triggers the DJI SDK registration method.  
This is a required action, everytime we launch our app, and before we attempt to connect to the Drone.

Example:
```
Future<void> _registerApp() async {
  try {
    await Dji.registerApp;
    developer.log(
      'registerApp succeeded',
      name: kLogKindDjiFlutterPlugin,
    );
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
```

#### Dji.connectDrone
The `Dji.connectDrone` method triggers the process of connecting to the Drone.

The Remote Controller and the DJI Drone need to be turned on.
The Remote Controller needs to be connected by USB cable to the mobile device running the app.
Once connected, the `DjiFlutterApi.setStatus()` method is triggered and the status is changed to "Connected".

Example:
```
Future<void> _connectDrone() async {
  try {
    await Dji.connectDrone;
    developer.log(
      'connectDrone succeeded',
      name: kLogKindDjiFlutterPlugin,
    );
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
```

#### Dji.disconnectDrone
The `Dji.disconnectDrone` method triggers the process of disconnecting from the Drone.

Once disconnected, the DjiFlutterApi.setStatus() method is triggered and the status is changed to "Disconnected".

Example:
```
Future<void> _disconnectDrone() async {
  try {
    await Dji.disconnectDrone;
    developer.log(
      'disconnectDrone succeeded',
      name: kLogKindDjiFlutterPlugin,
    );
  } on PlatformException catch (e) {
    developer.log(
      'disconnectDrone PlatformException Error',
      error: e,
      name: kLogKindDjiFlutterPlugin,
    );
  } catch (e) {
    developer.log(
      'disconnectDrone Error',
      error: e,
      name: kLogKindDjiFlutterPlugin,
    );
  }
}
```

#### Dji.delegateDrone
The `Dji.delegateDrone` method triggers the "listeners" to the Drone's statuses.
Upon any change to the Drone status properties - the SetState() method is triggerred (on the Flutter side).

Example:
```
Future<void> _delegateDrone() async {
  try {
    await Dji.delegateDrone;
    developer.log(
      'delegateDrone succeeded',
      name: kLogKindDjiFlutterPlugin,
    );
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
```

#### Dji.takeOff
The `Dji.takeOff` method commands the Drone to start take-off.
```
Future<void> _takeOff() async {
  try {
    await Dji.takeOff;
    developer.log(
      'Takeoff succeeded',
      name: kLogKindDjiFlutterPlugin,
    );
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
```

#### Dji.land
The `Dji.land` method commands the Drone to start landing.
```
Future<void> _land() async {
  try {
    await Dji.land;
    developer.log(
      'Land succeeded',
      name: kLogKindDjiFlutterPlugin,
    );
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
```

### Dji.start
The `Dji.start` method receives a Flight Timeline object and commands the Drone to start executing it.

The `Flight` class defines the different flight properties (e.g. location, waypoint, etc.) and provides tools to convert from and to JSON.

In the example below, the we first validate that the `DroneHomeLocation` exists and then we define our Flight object, which includes several Flight Elements.

A Flight Element has several types:
- takeOff
- land
- waypointMission
- singleShootPhoto
- startRecordVideo
- stopRecordVideo

The `waypointMission` consists of a list of waypoints.
Each waypoint can be defined in two ways: `location` or `vector`.

**Location** defines a waypoint by Latitude, Longitude and Altitude.

**Vector** defines a waypoint in relation to the "point of interest".
It's defined by 3 properties as follows:
- `distanceFromPointOfInterest`
	- The distance in meters between the "point of interest" and the Drone.
- `headingRelativeToPointOfInterest`
	- If you imagine a line between the "point of interest" (e.g. where you stand) and the Drone's Home Location - this is heading "0".
	- So the value of `headingRelativeToPointOfInterest` is the angle between heading "0" and where you want the Drone to be.
	- A positive heading angle is to your right. While a negative angle is to your left.
- `destinationAltitude`
	- This is the Drone's altitude at the waypoint.

**Explanation by example:**
Imagine you are the "point of interest", holding a "laser pointer".  
Everything is relative to the "line" between you and the Drone.  
If you point the laser to the Drone itself - that's "heading 0".  
If you want the first waypoint to be 30 degrees to your right, at a distance of 100 meters and altitude of 10 meters, you should set:
```
'vector': {
  'distanceFromPointOfInterest': 100,
  'headingRelativeToPointOfInterest': 30,
  'destinationAltitude': 10,
},
```

A full example showing how to use the Flight object and use the `Dji.start` method:
```
Future<void> _start() async {
  try {
    droneHomeLocation = FlightLocation(
        latitude: 32.2181125, longitude: 34.8674920, altitude: 0);

    if (droneHomeLocation == null) {
      developer.log(
          'No drone home location exist - unable to start the flight',
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
          // For example purposes, we set our Point of Interest a few meters away, relative to the Drone's Home Location
          'pointOfInterest': {
            'latitude': droneHomeLocation!.latitude + (5 * 0.00000899322),
            'longitude': droneHomeLocation!.longitude + (5 * 0.00000899322),
            'altitude': droneHomeLocation!.altitude,
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
            {
              // 'location': {
              //   'latitude': 32.2181125,
              //   'longitude': 34.8674920,
              //   'altitude': 20.0,
              // },
              'vector': {
                'distanceFromPointOfInterest': 20,
                'headingRelativeToPointOfInterest': 45,
                'destinationAltitude': 5,
              },
              //'heading': 0,
              'cornerRadiusInMeters': 5,
              'turnMode': 'clockwise',
              // 'gimbalPitch': 0,
            },
            {
              // 'location': {
              //   'latitude': 32.2181125,
              //   'longitude': 34.8674920,
              //   'altitude': 5.0,
              // },
              'vector': {
                'distanceFromPointOfInterest': 10,
                'headingRelativeToPointOfInterest': -45,
                'destinationAltitude': 3,
              },
              //'heading': 0,
              'cornerRadiusInMeters': 5,
              'turnMode': 'clockwise',
              // 'gimbalPitch': 0,
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
                droneHomeLocation: droneHomeLocation!);
      }
    }

    developer.log(
      'Flight Object: ${jsonEncode(flight)}',
      name: kLogKindDjiFlutterPlugin,
    );

    await Dji.start(flight: flight);
    developer.log(
      'Start Flight succeeded',
      name: kLogKindDjiFlutterPlugin,
    );
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
```
##### Notes
- The waypoint-mission maxFlightSpeed can get a maximum value of 15.0. If you enter a higher value - the waypoint mission won't start due to DJI limits.
- If you don't specify the `gimbalPitch`, the Flutter DJI Plugin will automatically calculate the Gimbal (Camera) angle to point to the Point of Interest.

#### Dji.mobileRemoteController
Update Mobile Remote Controller Sticks Data (via Wifi).
Controls the mobile remote controller - an on-screen sticks controller.
Available only when the drone is connected via Wifi.

Example:
```
Future<void> _updateMobileRemoteController() async {
  await Dji.mobileRemoteController(
    enabled: true,
    leftStickHorizontal: _leftStickHorizontal,
    leftStickVertical: _leftStickVertical,
    rightStickHorizontal: _rightStickHorizontal,
    rightStickVertical: _rightStickVertical,
  );
}
```

#### Dji.virtualStick
Update Virtual Stick flight controller data (via physical remote controller).
Control whether the virtual-stick mode is [enabled], and the [pitch], [roll], [yaw] and [verticalThrottle] of the Virtual Stick flight controller.
Available only when the drone is connected to the physical remote controller.

Example:
```
Future<void> _updateVirtualStick() async {
  await Dji.virtualStick(
    enabled: true,
    pitch: _virtualStickPitch,
    roll: _virtualStickRoll,
    yaw: _virtualStickYaw,
    verticalThrottle: _virtualStickVerticalThrottle,
  );
}
```

#### Dji.gimbalRotatePitch
Update Gimbal pitch value in degrees.
Controls the Gimbal pitch in [degrees] (-90..0) in Absolute Mode.
An angle of "0" degrees is aligned with the drone's "nose" (heading), and -90 degrees is the gimbal pointing the camera all the way down.

Example:
```
Future<void> _updateGimbalRotatePitch() async {
  await Dji.gimbalRotatePitch(
    degrees: _gimbalPitchInDegrees,
  );
}
```

#### Dji.getMediaList
Get the media files list from the Drone (SD card).
The `Dji.getMediaList` Returns a list of Media files. 
The index of each file is used to download or delete the file.

Example:
```
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
```

#### Dji.downloadMedia
Downloads a specific media file from the Drone's SD card (by Index).
The `fileIndex` is used to locate the relevant file from the Media List and download it.
The `getMediaList()` must be triggered before using `downloadMedia()`.

Example:
```
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
```

#### Dji.deleteMedia
Deletes a specific media file from the Drone's SD card (by Index).
The `fileIndex` is used to locate the relevant file from the Media List and delete it.
The `getMediaList()` must be triggered before using `downloadMedia()`.

Example:
```
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
```

#### Dji.videoFeedStart
Starts the DJI Video Feeder.
Triggers the DJI Camera Preview and streams YUV420p rawvideo byte-stream to the `DjiFlutterApi.sendVideo(Stream stream)` method.
The `Stream` class has a `data` property of type `Uint8List` optional.
The byte-stream can be converted to MP4, HLS or any other format using FFMPEG (see example code).

Example:
```
Future<void> _videoFeedStart() async {
  await Dji.videoFeedStart();
}
```

#### Dji.videoFeedStop
Stops the DJI Video Feeder.

Example:

```
Future<void> _videoFeedStop() async {
  await Dji.videoFeedStop();
}
```

#### sendVideo
**The `sendVideo()` method is triggered by the native host side of the plugin whenever a video byte-stream is sent.**

Example:
```
@override
void sendVideo(Stream stream) {
  if (stream.data != null && _videoFeedFile != null) {
    _videoFeedSink?.add(stream.data!);
  }
}
```

#### Dji.videoRecordStart
Starts the DJI Video Recorder.

Example:
```
Future<void> _videoRecordStart() async {
  await Dji.videoRecordStart();
}
```

#### Dji.videoRecordStop
Stops the DJI Video Recorder.

Example:

```
Future<void> _videoRecordStop() async {
  await Dji.videoRecordStop();
}
```

## TECH NOTES

### Plugin Creation Notes
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

### Pigeon
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

#### Pigeon Swift Example
https://github.com/DJI-Mobile-SDK-Tutorials/iOS-ImportAndActivateSDKInXcode-Swift

#### Pigeon Android Kotlin Example
https://github.com/gaaclarke/pigeon_plugin_example

Example how to use FlutterAPI (trigger a function from the native platform side):
https://github.com/glassmonkey/flutter_wifi/blob/master/android/app/src/main/kotlin/nagano/shunsuke/flutter_wifi_sample/WifiApi.kt


### Notes in regards to DJI SDK
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

### DJI References
**Useful Tutorial**  
https://www.tooploox.com/blog/automated-drone-missions-on-ios

**iOS Swift Media Manager Demo by @godfreynolan**  
Special thanks to this wonderful Swift tutorial by @godfreynolan:  
https://riis.com/blog/dji-sdk-tutorial-creating-a-media-manager-application/  
https://github.com/godfreynolan/MediaManagerSwift  

### Debugging Android over Wifi
Find your device IP Address through the Android > Settings > wifi.
Connect it via USB cable and then run the following from your Desktop terminal:
```
adb tcpip 4455
```
Then disconnect the USB cable, and run the following:
```
adb connect {{your-android-ip}}:4455
```

### Debugging iOS over Wifi
On iOS 14+, local network broadcast in apps need to be declared in the app's Info.plist.

Debug and profile Flutter apps and modules host VM services on the local network to support debugging features such as hot reload and DevTools.

To make your Flutter app or module attachable and debuggable, add a '_dartobservatory._tcp' value to the 'NSBonjourServices' key in your Info.plist for the Debug/Profile configurations.

For more information, see https://flutter.dev/docs/development/add-to-app/ios/project-setup#local-network-privacy-permissions

### A Tip in regards to Package Names
Due to inconsistencies between Google Play and Apple Appstore, there are differences in the "rules" that define what is a valid package-name.
For example, the "-" character cannot be used for Android, but is valid for iOS.
And with underscore there are issue when integrating with various Microsoft services (such as Microsoft Single Sign On).
So our tip here is to use package names without "-" or underscore, and that's why in the above example we used `djiExample` instead of `dji_example` or `dji-example`.

### Tips & Steps before publishing a Flutter / Dart Package
```
flutter analyze
dart doc
dart format .
dart pub publish --dry-run
dart pub publish
```

### Video Streaming & Decoding Tips
When using the `DJISDKManager.videoFeeder()?.primaryVideoFeed.add()` and listening to the incoming stream using `videoFeed()`, the DJI SDK generates a Byte Stream of h264 raw data.

If you save the video-data to a file, we can play it using FFPLAY like so:
```
ffplay -flags2 showall -f h264 -i ./video_feed.h264
```

We can convert it to .mp4 using FFMPEG like so:
```
ffmpeg -flags2 showall -f h264 -i ./video_feed.h264 ./video_feed.mp4
```

To output stream by pipe and play:
```
ffmpeg -i ./video_feed.mp4 -f mpegts - | ffplay -
```

*Note:* 
The DJI Flutter plugin converts the H264 to YUV420p and so the sendVideo() method streams rawvideo YUV frames (and not H264 raw).

To use FFMPEG in Flutter - use this package: 
https://pub.dev/packages/ffmpeg_kit_flutter

Tips about FFmpegKit:
1. Set the Podfile iOS target to 15.0
2. Look for the AppFrameworkInfo.plist and change the MinimumOSVersion to 15.0:
```
<key>MinimumOSVersion</key>
<string>15.0</string>
```
3. Go into your iOS folder and run `pod install`

What is FFMPEG: 
https://medium.com/hamza-solutions/ffmpeg-tool-with-flutter-ac1d68c2fddb

Flutter & MUX: 
https://blog.codemagic.io/build-video-streaming-with-flutter-and-mux/ 

Playing Byte Stream in Flutter:
https://github.com/flutter/flutter/issues/59387 
https://stackoverflow.com/questions/65821003/flutter-web-playing-uint8list-n-videoplayer/65834130 

VLC Player Tutorial: 
https://morioh.com/p/ddfd5bb6d250

Understanding Bytes in Dart: 
https://suragch.medium.com/working-with-bytes-in-dart-6ece83455721

Userful references in regards to DJI SDK Video decoding:
https://github.com/dji-sdk/Mobile-SDK-iOS/issues/383 
https://github.com/dji-sdk/Mobile-SDK-iOS/blob/798b8f2579cb08c643c18cd16b36cdfd3b0962f7/Sample%20Code/SwiftSampleCode/DJISDKSwiftDemo/Camera/VideoPreviewerAdapter.swift 
https://github.com/michael94ellis/iTello/blob/39bbceecb535395b8de9be3503db351d29f67a3e/iTello/VideoToolBox/VideoStreamManager.swift
https://www.raywenderlich.com/20518849-an-in-depth-dive-into-streaming-data-across-platform-channels-on-flutter
https://stackoverflow.com/questions/56170451/what-is-the-difference-between-methodchannel-eventchannel-basicmessagechannel/56171205#56171205
https://pub.dev/packages/chunked_stream
https://github.com/flutter/flutter/issues/71357

https://stackoverflow.com/questions/71613821/display-live-video-from-bytes-coming-from-websocket-in-flutter

https://stackoverflow.com/questions/56284630/how-to-read-dji-h264-fpv-feed-as-opencv-mat-object
https://github.com/tanersener/flutter-ffmpeg/issues/126
https://stackoverflow.com/questions/60988912/loading-video-files-from-device-as-bytedata-flutter

https://superuser.com/questions/1676797/how-to-convince-ffmpeg-that-input-is-raw-h264
https://stackoverflow.com/questions/64737547/flutter-dart-rewriting-image-in-the-same-format

How to pipe ffmpeg output to video_player flutter widget: 
https://github.com/tanersener/flutter-ffmpeg/issues/92

Techniques for reducing FFMPEG streaming latency:
https://stackoverflow.com/questions/16658873/how-to-minimize-the-delay-in-a-live-streaming-with-ffmpeg 

VLC Latency at start:
https://code.videolan.org/videolan/vlc/-/issues/26539

https://github.com/tanersener/flutter-ffmpeg/issues/71
https://programmer.group/basic-usage-of-ffmpeg.html
https://github.com/dart-lang/sdk/issues/32191
https://github.com/tanersener/flutter-ffmpeg/issues/92
https://github.com/tanersener/ffmpeg-kit/issues/350
https://pub.dev/packages/fijkplayer

https://github.com/tanersener/ffmpeg-kit-test/blob/main/flutter/test-app-local-dependency/lib/pipe_tab.dart
https://github.com/tanersener/ffmpeg-kit-test/blob/main/flutter/test-app-local-dependency/lib/video_util.dart

https://stackoverflow.com/questions/64847755/write-continuous-stream-to-file-flutter-dart

https://github.com/dji-sdk/DJIWidget/issues/9

Converting CVPixelBuffer to Data: 
https://gist.github.com/T1T4N/0ae90716b0c5d1bea39efe94512e1b72

Swift DJICustomVideoFrameExtractor example: 
https://github.com/Darko28/DJIML/blob/2499fcc50b64c1d22162753ce442da16c0b2c425/DJIML/DJIMLViewController.swift

HLS explained: 
https://www.toptal.com/apple/introduction-to-http-live-streaming-hls

Solution for how to enable the VideoDataListener on Android: 
(search for "codecManager.enabledYuvData(true);")
https://github.com/dji-sdk/Mobile-SDK-Android/issues/352

### FFMpeg Xcode BitCode Issue
If Xcode compilation fails with an error similar to this one:
```
...FFmpeg.framework/FFmpeg' does not contain bitcode. You must rebuild it with bitcode enabled (Xcode setting ENABLE_BITCODE)...
```
Open Xcode > for each Target (e.g. DJI-SDK-IOS, ffmpeg-kit-ios, etc.) - search for "BitCode" under the Build Settings section - and change to NO.

### Android issue with the better_player plugin
If you encounter the following error while trying to build the Android example project:
```
Could not find com.mapbox.mapboxsdk:mapbox-android-accounts:0.7.0.
```

Add `jcenter()` to your android/build.gradle file:
```
allprojects {
    repositories {
        ...
        jcenter()
    }
}
```
	