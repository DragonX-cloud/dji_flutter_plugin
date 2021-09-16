import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:async';

import 'package:dji/constants.dart';
import 'package:dji/flight.dart';
import 'package:dji/messages.dart';
import 'package:flutter/material.dart';

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
  String _droneStatus = 'Disconnected';
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
    _initDroneState();
    DjiFlutterApi.setup(this);
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

    // if (drone.status == 'Registered') {
    //   await Dji.connectDrone;
    // }
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

  Future<void> _timeline() async {
    try {
      await Dji.timeline;
      developer.log(
        'Timeline succeeded',
        name: kLogKindDjiFlutterPlugin,
      );
    } on PlatformException catch (e) {
      developer.log(
        'Timeline PlatformException Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    } catch (e) {
      developer.log(
        'Timeline Error',
        error: e,
        name: kLogKindDjiFlutterPlugin,
      );
    }
  }

  Future<void> _start() async {
    try {
      // List<FlightElement> timeline = [];

      // final FlightElement takeOffElement =
      //     FlightElement(type: FlightElementType.takeOff);
      // final FlightElement landElement =
      //     FlightElement(type: FlightElementType.land);

      // timeline.add(takeOffElement);
      // timeline.add(landElement);

      // Flight flight = Flight(timeline);

      Flight flight = Flight.fromJson({
        'timeline': [
          {
            'type': 'takeOff',
          },
          {
            'type': 'waypointMission',
            'pointOfInterest': {
              'longitude': 0.0,
              'latitude': 0.0,
              'altitude': 0.0,
            },
            'maxFlightSpeed': 25.0,
            'autoFlightSpeed': 10.0,
            'finishedAction': 'noAction',
            'headingMode': 'towardPointOfInterest',
            'flightPathMode': 'curved',
            'rotateGimbalPitch': true,
            'exitMissionOnRCSignalLost': true,
            'waypoints': [
              {
                // 'location': {
                //   'longitude': 1.0,
                //   'latitude': 1.0,
                //   'altitude': 1.0,
                // },
                'vector': {
                  'distanceFromPointOfInterest': 100,
                  'headingRelativeToPointOfInterest': 45,
                  'destinationAltitude': 20,
                },
                //'heading': 0,
                'cornerRadiusInMeters': 5,
                'turnMode': 'clockwise',
                'gimbalPitch': 0,
              },
              {
                // 'location': {
                //   'longitude': 2.0,
                //   'latitude': 2.0,
                //   'altitude': 2.0,
                // },
                'vector': {
                  'distanceFromPointOfInterest': 10,
                  'headingRelativeToPointOfInterest': -45,
                  'destinationAltitude': 5,
                },
                //'heading': 0,
                'cornerRadiusInMeters': 5,
                'turnMode': 'clockwise',
                'gimbalPitch': 0,
              },
            ],
          },
          {
            'type': 'land',
          },
        ],
      });

      droneHomeLocation =
          FlightLocation(latitude: 0.0, longitude: 0.0, altitude: 0);

      if (droneHomeLocation == null) {
        developer.log(
            'No drone home location exist - unable to start the flight',
            name: kLogKindDjiFlutterPlugin);
        return;
      }

      // Converting any vector definitions in waypoint-mission to locations
      for (dynamic element in flight.timeline) {
        if (element.type == FlightElementType.waypointMission) {
          CoordinatesConvertion.convertWaypointMissionVectorsToLocations(
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
                              child: Text('Connect'),
                              onPressed: () async {
                                await _connectDrone();
                              },
                            ),
                            ElevatedButton(
                              key: Key('disconnectDroneButton'),
                              child: Text('Disconnect'),
                              onPressed: () async {
                                await _disconnectDrone();
                              },
                            ),
                            ElevatedButton(
                              key: Key('delegateButton'),
                              child: Text('Delegate'),
                              onPressed: () async {
                                await _delegateDrone();
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
                            ElevatedButton(
                              key: Key('timelineDroneButton'),
                              child: Text('Timeline'),
                              onPressed: () async {
                                await _timeline();
                              },
                            ),
                            ElevatedButton(
                              key: Key('start'),
                              child: Text('Start'),
                              onPressed: () async {
                                await _start();
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
                              value: _droneStatus,
                            ),
                            dronePropertyRow(
                              label: 'Drone Battery',
                              value: _droneBatteryPercent + '%',
                            ),
                            dronePropertyRow(
                              label: 'Altitude',
                              value: _droneAltitude,
                            ),
                            dronePropertyRow(
                              label: 'Latitude',
                              value: _droneLatitude,
                            ),
                            dronePropertyRow(
                              label: 'Longitude',
                              value: _droneLongitude,
                            ),
                            dronePropertyRow(
                              label: 'Speed',
                              value: _droneSpeed,
                            ),
                            dronePropertyRow(
                              label: 'Roll',
                              value: _droneRoll,
                            ),
                            dronePropertyRow(
                              label: 'Pitch',
                              value: _dronePitch,
                            ),
                            dronePropertyRow(
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
