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
	
	var drone : DJIAircraft?
	var droneCurrentLocation : CLLocation?
	
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
		  print("=== iOS Error: Host (Mobile Device) Battery info unavailable; \(device.batteryState.rawValue)");
		  result.level = -1
		} else {
		  print("=== iOS: Host (Mobile Device) Battery level \(device.batteryLevel)");
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
		
//		DJISDKManager.enableBridgeMode(withBridgeAppIP: "192.168.1.105")
		DJISDKManager.startConnectionToProduct()
	}
	
	public func disconnectDrone(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== iOS: Disconnect Drone Started")
		DJISDKManager.stopConnectionToProduct()
	}
	
	public func takeOff(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneFlightController = drone?.flightController {
			print("=== iOS: Takeoff Started")
			_droneFlightController.startTakeoff(completion: nil)
		} else {
			print("=== iOS: Takeoff Failed - No Flight Controller")
		}
	}
	
	public func land(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneFlightController = drone?.flightController {
			print("=== iOS: Landing Started")
			_droneFlightController.startLanding(completion: nil)
		} else {
			print("=== iOS: Landing Failed - No Flight Controller")
		}
	}
	
	public func timeline(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneFlightController = drone?.flightController {
			
			// First we check if a timeline is already running
			if (DJISDKManager.missionControl()?.isTimelineRunning == true) {
				print("=== iOS: Error - Timeline already running")
				return
			} else {
				print("=== iOS: Timeline Started")
			}
			
			let offset = 0.0000899322
			
//			let takeOffElement = DJITakeOffAction()
//			let error = DJISDKManager.missionControl()?.scheduleElement(takeOffElement)
//			if error != nil {
//				NSLog("Error scheduling element \(String(describing: error))")
//			 	return;
//			}
			
//			guard let droneLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation) else {
//				print("=== iOS: Timeline Failed - No droneLocationKey")
//				return
//			}
//			guard let droneLocationValue = DJISDKManager.keyManager()?.getValueFor(droneLocationKey) else {
//				print("=== iOS: Timeline Failed - No droneLocationValue")
//				return
//			}
//			let droneLocation = droneLocationValue.value as! CLLocation
//			let droneCoordinates = droneLocation.coordinate

			guard let droneCoordinates = droneCurrentLocation?.coordinate else {
				print("=== iOS: Timeline Failed - No droneCurrentLocationCoordinates")
				return
			}
			
			if !CLLocationCoordinate2DIsValid(droneCoordinates) {
				print("=== iOS: Timeline Failed - Invalid droneCoordinates")
				return
			}
			
			// Set Home Coordinates
			drone?.flightController?.setHomeLocation(droneCurrentLocation!)
			
			var scheduledElements = [DJIMissionAction]()
			
			// Take Off
			scheduledElements.append(DJITakeOffAction())
			
			// Goto Waypoint
			let wp1 = CLLocationCoordinate2DMake(droneCoordinates.latitude + offset, droneCoordinates.longitude)
			if let gotoElement = DJIGoToAction(coordinate: wp1, altitude: 15) {
				scheduledElements.append(gotoElement)
			}
			
			// Goto Waypoint
			let wp2 = CLLocationCoordinate2DMake(droneCoordinates.latitude, droneCoordinates.longitude - offset)
			if let gotoElement = DJIGoToAction(coordinate: wp2, altitude: 15) {
				scheduledElements.append(gotoElement)
			}
			
			// Hot Point
			let wp3 = CLLocationCoordinate2DMake(droneCoordinates.latitude + offset, droneCoordinates.longitude)
			if let hotPointElement = hotPointAction(hotpoint: wp3, altitude: 15, radius: 5) {
				scheduledElements.append(hotPointElement)
			}
			
			// Zoom Out (Dronie)
			// TBD
			
			// Goto Home
			scheduledElements.append(DJIGoHomeAction())
			
			// Land
			scheduledElements.append(DJILandAction())

			var timelineSchedulingCompleted : Bool = true
			for element in scheduledElements {
				let error = DJISDKManager.missionControl()?.scheduleElement(element)
				if error != nil {
					NSLog("=== iOS: Timeline Failed - Error scheduling element \(String(describing: error))")
					timelineSchedulingCompleted = false
					return;
				}
			}
			if (timelineSchedulingCompleted) {
				// Starting Motors
				_droneFlightController.turnOnMotors(completion: nil)
			
				// Starting the Timeline Mission
				DJISDKManager.missionControl()?.startTimeline()
			}
			
		} else {
			print("=== iOS: Timeline Failed - No Flight Controller")
		}
	}
	
	func hotPointAction(hotpoint : CLLocationCoordinate2D, altitude : Float, radius: Float) -> DJIHotpointAction? {
        if !CLLocationCoordinate2DIsValid(hotpoint) {
            return nil
        }
        
        let mission = DJIHotpointMission()
        
        mission.hotpoint = hotpoint
        mission.altitude = altitude
        mission.radius = radius
        DJIHotpointMissionOperator.getMaxAngularVelocity(forRadius: Double(mission.radius), withCompletion: {(velocity:Float, error:Error?) in
            mission.angularVelocity = velocity
        })
        mission.startPoint = .nearest
        mission.heading = .towardHotpoint
        
        return DJIHotpointAction(mission: mission, surroundingAngle: 180)
    }
	
	//MARK: - DJISDKManager Delegate Methods
    
	public func productConnected(_ product: DJIBaseProduct?) {
		// DJI Product is available only after registration and connection. So we initialize it here.
		if let _ = product {
            if DJISDKManager.product()!.isKind(of: DJIAircraft.self) && (DJISDKManager.product()! as! DJIAircraft).flightController != nil {
                print("=== iOS: Product Connected")
                
                // Setting the delegates
                drone = (DJISDKManager.product()! as! DJIAircraft)
				drone!.flightController!.delegate = self
				drone!.battery!.delegate = self
				
				_fltSetDroneStatus("Connected")
			} else {
				print("=== iOS: Product Connect Error - flightController does not exist")
			}
        }
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
			//print("= iOS: Altitude - \(altitude)")
			_droneAltitude = altitude as NSNumber
		}
		
		// Updating the drone's current location coordinates variable
		if let droneLocation = state.aircraftLocation {
			droneCurrentLocation = droneLocation
		}
		
		if let latitude = state.aircraftLocation?.coordinate.latitude {
			//print("= iOS: Latitude - \(latitude)")
			_droneLatitude = latitude as NSNumber
		}
		
		if let longitude = state.aircraftLocation?.coordinate.longitude {
			//print("= iOS: Longitude - \(longitude)")
			_droneLongitude = longitude as NSNumber
		}
		
		if let speed = state.aircraftLocation?.speed {
			//print("= iOS: Speed - \(speed)")
			_droneSpeed = speed as NSNumber
		}
		
		//print("= iOS: Roll \(state.attitude.roll) | Pitch \(state.attitude.pitch) | Yaw \(state.attitude.yaw)")
		_droneRoll = state.attitude.roll as NSNumber
		_dronePitch = state.attitude.pitch as NSNumber
		_droneYaw = state.attitude.yaw as NSNumber
		
		// Confirm Landing
		if (state.isLandingConfirmationNeeded == true) {
			fc.confirmLanding(completion: nil)
		}
		
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
				//print("=== iOS: setDroneStatus Closure Success")
			}
		}
	}
}

