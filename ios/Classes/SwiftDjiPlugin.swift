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
		let api : FLTDjiHostApi & NSObjectProtocol = SwiftDjiPlugin.init()
		FLTDjiHostApiSetup(messenger, api)
		fltDjiFlutterApi = FLTDjiFlutterApi.init(binaryMessenger: messenger)
	}
	
	private func _fltSetStatus(_ status: String) {
		fltDrone.status = status
		
		SwiftDjiPlugin.fltDjiFlutterApi?.setStatusDrone(fltDrone) {e in
			if let error = e {
				print("=== iOS: Error: SetStatus Closure Error")
				NSLog("error: %@", error.localizedDescription)
			} else {
				print("=== iOS: setStatus Closure Success: \(status)")
			}
		}
	}
	
	//MARK: - Dji Plugin Methods
	
	public func getPlatformVersionWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> FLTVersion? {
		let result = FLTVersion.init()
		result.string = "iOS " + UIDevice.current.systemVersion
		return result
	}
	
	public func getBatteryLevelWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> FLTBattery? {
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
	
	public func registerAppWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== iOS: Register App Started")
		DJISDKManager.registerApp(with: self)
	}
	
	public func connectDroneWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== iOS: Connect Drone Started")
		
//		DJISDKManager.enableBridgeMode(withBridgeAppIP: "192.168.1.105")
		DJISDKManager.startConnectionToProduct()
	}
	
	public func disconnectDroneWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== iOS: Disconnect Drone Started")
		DJISDKManager.stopConnectionToProduct()
	}
	
	public func delegateDroneWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== iOS: Delegate Drone Started")
		if let product = DJISDKManager.product() {
			if product.isKind(of: DJIAircraft.self) {
				drone = (DJISDKManager.product()! as! DJIAircraft)
				
				if let _ = drone?.flightController {
					print("=== iOS: Drone Flight Controller Delegate successfuly configured")
					drone!.flightController!.delegate = self
				} else {
					print("=== iOS: Product Connect Error - No Flight Controller Object")
					_fltSetStatus("Error")
					return
				}
				
				if let _ = drone?.battery {
					print("=== iOS: Drone Battery Delegate successfuly configured")
					drone!.battery!.delegate = self
				} else {
					print("=== iOS: Product Connect Error - No Battery Object")
					_fltSetStatus("Error")
					return
				}
				
				print("=== iOS: Delegations completed")
				_fltSetStatus("Delegated")

			} else {
				print("=== iOS: Error - Delegations - DJI Aircraft Object does not exist")
			}
		} else {
			print("=== iOS: Error - Delegations - DJI Product Object does not exist")
		}
	}
	
	public func takeOffWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneFlightController = drone?.flightController {
			print("=== iOS: Takeoff Started")
			_droneFlightController.startTakeoff(completion: nil)
		} else {
			print("=== iOS: Takeoff Failed - No Flight Controller")
		}
	}
	
	public func landWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneFlightController = drone?.flightController {
			print("=== iOS: Landing Started")
			_droneFlightController.startLanding(completion: nil)
		} else {
			print("=== iOS: Landing Failed - No Flight Controller")
		}
	}
	
	public func timelineWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneFlightController = drone?.flightController {
			
			// First we check if a timeline is already running
			if (DJISDKManager.missionControl()?.isTimelineRunning == true) {
				print("=== iOS: Error - Timeline already running")
				return
			} else {
				print("=== iOS: Timeline Started")
			}

			guard let droneCoordinates = droneCurrentLocation?.coordinate else {
				print("=== iOS: Timeline Failed - No droneCurrentLocationCoordinates")
				return
			}
			
			if !CLLocationCoordinate2DIsValid(droneCoordinates) {
				print("=== iOS: Timeline Failed - Invalid droneCoordinates")
				return
			}
			
			// Set Home Coordinates
			let droneHomeLocation = CLLocation(latitude: droneCoordinates.latitude, longitude: droneCoordinates.longitude)
			let droneHomeCoordinates = droneHomeLocation.coordinate
			_droneFlightController.setHomeLocation(droneHomeLocation)
			//_droneFlightController.setHomeLocationUsingAircraftCurrentLocationWithCompletion(nil)
			
			var scheduledElements = [DJIMissionControlTimelineElement]()
			
			// Take Off
			scheduledElements.append(DJITakeOffAction())
			
			// Waypoint Mission
			if let wayPointMission = waypointMission(droneHomeCoordinates) {
				scheduledElements.append(wayPointMission)
			}
			
			// Hot Point
			let hotPointCoordinates = CLLocationCoordinate2DMake(droneHomeCoordinates.latitude, droneHomeCoordinates.longitude)
			if let hotPointElement = hotPointAction(hotpoint: hotPointCoordinates, altitude: 15, radius: 5) {
				scheduledElements.append(hotPointElement)
			}
			
			// Goto Home
//			scheduledElements.append(DJIGoHomeAction())

			// Goto Waypoint (Home)
			if let gotoElement = DJIGoToAction(coordinate: droneHomeCoordinates, altitude: 15) {
				scheduledElements.append(gotoElement)
			}
			
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
	
	public func startFlightJson(_ flightJson: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== iOS: Start Flight: \(flightJson)")
	}
	
	//Mark: - DJI Timeline Methods
	
	func waypointMission(_ droneCoordinates : CLLocationCoordinate2D) -> DJIWaypointMission? {
        let mission = DJIMutableWaypointMission()
        mission.maxFlightSpeed = 15
        mission.autoFlightSpeed = 8
        mission.finishedAction = .noAction
        mission.headingMode = .usingWaypointHeading
        mission.flightPathMode = .curved
        mission.rotateGimbalPitch = true
        mission.exitMissionOnRCSignalLost = true
        mission.gotoFirstWaypointMode = .pointToPoint
        mission.repeatTimes = 1
        
//        guard let droneLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation) else {
//            return nil
//        }
//
//        guard let droneLocationValue = DJISDKManager.keyManager()?.getValueFor(droneLocationKey) else {
//            return nil
//        }
//
//		  let droneLocation = droneLocationValue.value as! CLLocation
//        let droneCoordinates = droneLocation.coordinate
        
		if !CLLocationCoordinate2DIsValid(droneCoordinates) {
            return nil
        }

        mission.pointOfInterest = droneCoordinates
        let offset = 0.0000899322
        
        let loc1 = CLLocationCoordinate2DMake(droneCoordinates.latitude, droneCoordinates.longitude)
        let waypoint1 = DJIWaypoint(coordinate: loc1)
        waypoint1.altitude = 2
        waypoint1.heading = 0
        waypoint1.actionRepeatTimes = 1
        waypoint1.actionTimeoutInSeconds = 30
        waypoint1.cornerRadiusInMeters = 5
        waypoint1.turnMode = .clockwise
        waypoint1.gimbalPitch = 0
        
        let loc2 = CLLocationCoordinate2DMake(droneCoordinates.latitude + (offset * 5), droneCoordinates.longitude)
        let waypoint2 = DJIWaypoint(coordinate: loc2)
        waypoint1.altitude = 15
        //waypoint1.heading = 0
        waypoint1.actionRepeatTimes = 1
        waypoint1.actionTimeoutInSeconds = 30
        waypoint1.cornerRadiusInMeters = 5
        waypoint1.turnMode = .clockwise
        waypoint1.gimbalPitch = -30
        
        let loc3 = CLLocationCoordinate2DMake(droneCoordinates.latitude, droneCoordinates.longitude + (offset * 5))
        let waypoint3 = DJIWaypoint(coordinate: loc3)
        waypoint2.altitude = 15
        //waypoint2.heading = 0
        waypoint2.actionRepeatTimes = 1
        waypoint2.actionTimeoutInSeconds = 30
        waypoint2.cornerRadiusInMeters = 5
        waypoint2.turnMode = .clockwise
        waypoint2.gimbalPitch = -45
        
        mission.add(waypoint1)
        mission.add(waypoint2)
        mission.add(waypoint3)
        
        return DJIWaypointMission(mission: mission)
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
	
	public func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
		print("Downloading database: \(progress.completedUnitCount) / \(progress.totalUnitCount)")
	}
    
    public func appRegisteredWithError(_ error: Error?) {
		if (error != nil) {
			print("=== iOS: Error: Register app failed! Please enter your app key and check the network.")
		} else {
			print("=== iOS: Register App Successed!")
			_fltSetStatus("Registered")
		}
	}
	
	public func productConnected(_ product: DJIBaseProduct?) {
		// DJI Product is available only after registration and connection. So we initialize it here.
		if let _ = product {
			print("=== iOS: Product Connected successfuly")
			_fltSetStatus("Connected")
        } else {
			print("=== iOS: Error Connecting Product - DJIBaseProduct does not exist")
		}
	}
	
	public func productDisconnected() {
		print("=== iOS: Product Disconnected")
		_fltSetStatus("Disconnected")
	}

	//MARK: - DJIBattery Delegate Methods
	
	public func battery(_ battery: DJIBattery, didUpdate state: DJIBatteryState) {
		// Updating Flutter
		fltDrone.batteryPercent = Double(state.chargeRemainingInPercent) as NSNumber
		//print("=== iOS: Battery Percent \(fltDrone.batteryPercent ?? 0)%")
		
		SwiftDjiPlugin.fltDjiFlutterApi?.setStatusDrone(fltDrone) {e in
			if let error = e {
				print("=== iOS: Error: SetStatus Closure Error")
				NSLog("error: %@", error.localizedDescription)
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
		
		SwiftDjiPlugin.fltDjiFlutterApi?.setStatusDrone(fltDrone) {e in
			if let error = e {
				print("=== iOS: Error: SetStatus Closure Error")
				NSLog("error: %@", error.localizedDescription)
			}
		}
	}
}

