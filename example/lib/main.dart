import 'package:dji/messages.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:dji/dji.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements DjiFlutterApi {
  String _platformVersion = 'Unknown';
  int _batteryLevel = -1;
  String _droneStatus = 'Disconnected';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    DjiFlutterApi.setup(this);
  }

  @override
  void setDroneStatus(Drone arg) {
    setState(() {
      _droneStatus = arg.droneStatus ?? 'Disconnected';
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
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

    try {
      await Dji.registerDjiApp;
      print('registerDjiApp succeeded.');
    } on PlatformException catch (e) {
      print('registerDjiApp PlatformException Error: ${e.message}');
    } catch (e) {
      print('registerDjiApp Error: ${e.toString()}');
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _batteryLevel = batteryLevel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(children: [
              Text('Running on: $_platformVersion\n'),
              Text('Battery level: $_batteryLevel\n'),
              Text('Drone Status: $_droneStatus\n'),
            ]),
          ),
        ),
      ),
    );
  }
}
