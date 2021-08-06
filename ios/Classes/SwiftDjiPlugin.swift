// import Flutter
// import UIKit

// public class SwiftDjiPlugin: NSObject, FlutterPlugin {
//   public static func register(with registrar: FlutterPluginRegistrar) {
//     let channel = FlutterMethodChannel(name: "dji", binaryMessenger: registrar.messenger())
//     let instance = SwiftDjiPlugin()
//     registrar.addMethodCallDelegate(instance, channel: channel)
//   }

//   public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//     result("iOS " + UIDevice.current.systemVersion)
//   }
// }

import Flutter
import UIKit
import DJISDK

public class SwiftDjiPlugin: FLTDjiFlutterApi, FlutterPlugin, FLTDjiHostApi, DJISDKManagerDelegate, DJIFlightControllerDelegate, DJIBatteryDelegate {
	
	static var fltDjiFlutterApi : FLTDjiFlutterApi?
	let fltDrone = FLTDrone()
	
	var aircraft : DJIAircraft?
	
	public static func register(with registrar: FlutterPluginRegistrar) {
		let messenger : FlutterBinaryMessenger = registrar.messenger()
		let api : FLTDjiHostApi = SwiftDjiPlugin.init()
		FLTDjiHostApiSetup(messenger, api)
		fltDjiFlutterApi = FLTDjiFlutterApi.init(binaryMessenger: messenger)
	}

	private func _fltSetDroneStatus(_ status: String) {
		fltDrone.status = status
		
		SwiftDjiPlugin.fltDjiFlutterApi?.setDroneStatus(fltDrone) {e in
			if let error = e {
				print("=== iOS: Error: SetDroneStatus Closure Error")
				NSLog("error: %@", error.localizedDescription)
			} else {
				print("=== iOS: setDroneStatus Closure Success: \(status)")
			}
		}
	}
	
	//MARK: - Dji Plugin Methods

	public func getPlatformVersion(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> FLTVersion? {
		let result = FLTVersion.init()
		result.string = "iOS " + UIDevice.current.systemVersion
		return result
	}

	public func getBatteryLevel(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> FLTBattery? {
		let result = FLTBattery.init()

		let device = UIDevice.current
		device.isBatteryMonitoringEnabled = true
		if device.batteryState == .unknown {
		  print("Error: Battery info unavailable; \(device.batteryState.rawValue)");
		  result.level = -1
		} else {
		  print("Error: Battery level \(device.batteryLevel)");
		  result.level = Int(device.batteryLevel * 100) as NSNumber
		}

		return result
	}

	public func registerApp(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== iOS: Register App Started")
		DJISDKManager.registerApp(with: self)
	}

	public func connectDrone(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== iOS: Connect Drone Started")
		DJISDKManager.startConnectionToProduct()
	}
	
	public func disconnectDrone(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== iOS: Disconnect Drone Started")
		DJISDKManager.stopConnectionToProduct()
	}
	
	public func takeOff(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== iOS: Takeoff Started")
		
		aircraft?.flightController?.startTakeoff(completion: nil)
		
		// Takeoff using Timeline
		/*
		let element = DJITakeOffAction()
		let error = DJISDKManager.missionControl()?.scheduleElement(element)
		
		if error != nil {
			NSLog("Error scheduling element \(String(describing: error))")
			return;
		}
		
		var scheduledElements = [DJIMissionAction]()
		scheduledElements.append(element)
		
		DJISDKManager.missionControl()?.startTimeline()
		*/
	}
	
	public func land(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== iOS: Landing Started")
		aircraft?.flightController?.startLanding(completion: nil)
	}
	
	//MARK: - DJISDKManager Delegate Methods
    
	public func productConnected(_ product: DJIBaseProduct?) {
		print("=== iOS: Product Connected")
		_fltSetDroneStatus("Connected")
	}

	public func productDisconnected() {
		print("=== iOS: Product Disconnected")
		_fltSetDroneStatus("Disconnected")
	}

	public func appRegisteredWithError(_ error: Error?) {
		if (error != nil) {
			print("=== iOS: Error: Register app failed! Please enter your app key and check the network.")
		} else {
			print("=== iOS: Register App Successed!")
			
			aircraft = DJISDKManager.product() as? DJIAircraft
			
			_fltSetDroneStatus("Registered")
		}
	}

	public func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
		print("Downloading database: \(progress.completedUnitCount) / \(progress.totalUnitCount)")
	}
	
	//MARK: - DJIBattery Delegate Methods
	
	public func battery(_ battery: DJIBattery, didUpdate state: DJIBatteryState) {
		// Updating Flutter
		print("=== iOS: Battery Pecentage - \(state.chargeRemainingInPercent)")
		fltDrone.batteryPercent = state.chargeRemainingInPercent as NSNumber
		
		SwiftDjiPlugin.fltDjiFlutterApi?.setDroneStatus(fltDrone) {e in
			if let error = e {
				print("=== iOS: Error: SetDroneStatus Closure Error")
				NSLog("error: %@", error.localizedDescription)
			} else {
				print("=== iOS: setDroneStatus Closure Success")
			}
		}
		
	}
	
	//MARK: - DJIFlightController Delegate Methods
	
	public func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
		var _droneAltitude: NSNumber = 0
		var _droneLatitude: NSNumber = 0
		var _droneLongitude: NSNumber = 0
		var _droneSpeed: NSNumber = 0
		var _droneRoll: NSNumber = 0
		var _dronePitch: NSNumber = 0
		var _droneYaw: NSNumber = 0
		
		if let altitude = state.aircraftLocation?.altitude {
			print("= iOS: Altitude - \(altitude)")
			_droneAltitude = altitude as NSNumber
		}
		
		if let latitude = state.aircraftLocation?.coordinate.latitude {
			print("= iOS: Latitude - \(latitude)")
			_droneLatitude = latitude as NSNumber
		}
		
		if let longitude = state.aircraftLocation?.coordinate.longitude {
			print("= iOS: Longitude - \(longitude)")
			_droneLongitude = longitude as NSNumber
		}
		
		if let speed = state.aircraftLocation?.speed {
			print("= iOS: Speed - \(speed)")
			_droneSpeed = speed as NSNumber
		}
		
		print("= iOS: Roll \(state.attitude.roll) | Pitch \(state.attitude.pitch) | Yaw \(state.attitude.yaw)")
		_droneRoll = state.attitude.roll as NSNumber
		_dronePitch = state.attitude.pitch as NSNumber
		_droneYaw = state.attitude.yaw as NSNumber
		
		// Updating Flutter
		fltDrone.altitude = _droneAltitude
		fltDrone.latitude = _droneLatitude
		fltDrone.longitude = _droneLongitude
		fltDrone.speed = _droneSpeed
		fltDrone.roll = _droneRoll
		fltDrone.pitch = _dronePitch
		fltDrone.yaw = _droneYaw
		
		SwiftDjiPlugin.fltDjiFlutterApi?.setDroneStatus(fltDrone) {e in
			if let error = e {
				print("=== iOS: Error: SetDroneStatus Closure Error")
				NSLog("error: %@", error.localizedDescription)
			} else {
				print("=== iOS: setDroneStatus Closure Success")
			}
		}
	}
	
}

