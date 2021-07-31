import 'package:dji/messages.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:dji/dji.dart';

import 'constants.dart';

class HomeWidget extends StatefulWidget {
  @override
  _HomeWidgetState createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> implements DjiFlutterApi {
  String _platformVersion = 'Unknown';
  // int _batteryLevel = -1;
  String? _droneStatus = 'Disconnected';
  double? _droneBatteryPercent = 0.0;
  double? _droneAltitude = 0.0;
  double? _droneLatitude = 0.0;
  double? _droneLongitude = 0.0;
  double? _droneSpeed = 0.0;
  double? _droneRoll = 0.0;
  double? _dronePitch = 0.0;
  double? _droneYaw = 0.0;

  @override
  void initState() {
    super.initState();
    _initDroneState();
    DjiFlutterApi.setup(this);
  }

  // This function is triggered by the Native Host side whenever the Drone Status is changed.
  @override
  void setDroneStatus(Drone drone) async {
    setState(() {
      _droneStatus = drone.status ?? 'Disconnected';
      _droneAltitude = drone.altitude;
      _droneBatteryPercent = drone.batteryPercent;
      _droneLatitude = drone.latitude;
      _droneLongitude = drone.longitude;
      _droneSpeed = drone.speed;
      _droneRoll = drone.roll;
      _dronePitch = drone.pitch;
      _droneYaw = drone.yaw;
    });

    if (drone.status == 'Registered') {
      await Dji.connectDrone;
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initDroneState() async {
    String platformVersion;
    int batteryLevel;

    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await Dji.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    try {
      batteryLevel = await Dji.batteryLevel ?? 0;
    } on PlatformException {
      batteryLevel = -1;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      // _batteryLevel = batteryLevel;
    });
  }

  Future<void> _registerApp() async {
    try {
      await Dji.registerApp;
      print('registerApp succeeded.');
    } on PlatformException catch (e) {
      print('registerApp PlatformException Error: ${e.message}');
    } catch (e) {
      print('registerApp Error: ${e.toString()}');
    }
  }

  Future<void> _connectDrone() async {
    try {
      await Dji.connectDrone;
      print('connectDrone succeeded.');
    } on PlatformException catch (e) {
      print('connectDrone PlatformException Error: ${e.message}');
    } catch (e) {
      print('connectDrone Error: ${e.toString()}');
    }
  }

  Future<void> _disconnectDrone() async {
    try {
      await Dji.disconnectDrone;
      print('disconnectDrone succeeded.');
    } on PlatformException catch (e) {
      print('disconnectDrone PlatformException Error: ${e.message}');
    } catch (e) {
      print('disconnectDrone Error: ${e.toString()}');
    }
  }

  Future<void> _takeOff() async {
    try {
      await Dji.takeOff;
      print('Takeoff succeeded.');
    } on PlatformException catch (e) {
      print('Takeoff PlatformException Error: ${e.message}');
    } catch (e) {
      print('Takeoff Error: ${e.toString()}');
    }
  }

  Future<void> _land() async {
    try {
      await Dji.land;
      print('Land succeeded.');
    } on PlatformException catch (e) {
      print('Land PlatformException Error: ${e.message}');
    } catch (e) {
      print('Land Error: ${e.toString()}');
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
              padding: EdgeInsets.all(kSpacer),
              height: MediaQuery.of(context).size.height * 0.2,
              color: Colors.black54,
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
                              key: Key('registerAppButton'),
                              child: Text('Register App'),
                              onPressed: () async {
                                await _registerApp();
                              },
                            ),
                            ElevatedButton(
                              key: Key('connectDroneButton'),
                              child: Text('Connect Drone'),
                              onPressed: () async {
                                await _connectDrone();
                              },
                            ),
                            ElevatedButton(
                              key: Key('disconnectDroneButton'),
                              child: Text('Disconnect Drone'),
                              onPressed: () async {
                                await _disconnectDrone();
                              },
                            ),
                            ElevatedButton(
                              key: Key('takeOffDroneButton'),
                              child: Text('Take Off'),
                              onPressed: () async {
                                await _takeOff();
                              },
                            ),
                            ElevatedButton(
                              key: Key('landDroneButton'),
                              child: Text('Land'),
                              onPressed: () async {
                                await _land();
                              },
                            ),
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
                            dronePropertyRow(
                              label: 'Running on',
                              value: _platformVersion,
                            ),
                            // dronePropertyRow(
                            //   label: 'Battery Level',
                            //   value: _batteryLevel.toString(),
                            // ),
                            dronePropertyRow(
                              label: 'Drone Status',
                              value: _droneStatus ?? '',
                            ),
                            dronePropertyRow(
                              label: 'Drone Battery',
                              value: _droneBatteryPercent.toString() + ' %',
                            ),
                            dronePropertyRow(
                              label: 'Altitude',
                              value: _droneAltitude.toString(),
                            ),
                            dronePropertyRow(
                              label: 'Latitude',
                              value: _droneLatitude.toString(),
                            ),
                            dronePropertyRow(
                              label: 'Longitude',
                              value: _droneLongitude.toString(),
                            ),
                            dronePropertyRow(
                              label: 'Speed',
                              value: _droneSpeed.toString(),
                            ),
                            dronePropertyRow(
                              label: 'Roll',
                              value: _droneRoll.toString(),
                            ),
                            dronePropertyRow(
                              label: 'Pitch',
                              value: _dronePitch.toString(),
                            ),
                            dronePropertyRow(
                              label: 'Yaw',
                              value: _droneYaw.toString(),
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

class dronePropertyRow extends StatelessWidget {
  const dronePropertyRow({
    required this.label,
    required this.value,
  });

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
