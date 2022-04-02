import Foundation
import DJISDK
import DJIWidget
import Flutter
import UIKit

public class SwiftDjiPlugin: FLTDjiFlutterApi, FlutterPlugin, FLTDjiHostApi, DJISDKManagerDelegate, DJIFlightControllerDelegate, DJIBatteryDelegate {
	
	static var fltDjiFlutterApi: FLTDjiFlutterApi?
	let fltDrone = FLTDrone()

	var drone: DJIAircraft?
	var droneCurrentLocation: CLLocation?

	var flight: Flight?

	public static func register(with registrar: FlutterPluginRegistrar) {
		let messenger: FlutterBinaryMessenger = registrar.messenger()
		let api: FLTDjiHostApi & NSObjectProtocol = SwiftDjiPlugin()
		FLTDjiHostApiSetup(messenger, api)
		fltDjiFlutterApi = FLTDjiFlutterApi(binaryMessenger: messenger)
	}

	private func _fltSetStatus(_ status: String) {
		fltDrone.status = status

		SwiftDjiPlugin.fltDjiFlutterApi?.setStatusDrone(fltDrone) { e in
			if let error = e {
				print("=== DjiPlugin iOS: Error: SetStatus Closure Error")
				NSLog("error: %@", error.localizedDescription)
			} else {
				print("=== DjiPlugin iOS: setStatus Closure Success: \(status)")
			}
		}
	}

	// MARK: - Dji Plugin Methods

	public func getPlatformVersionWithError(_: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> FLTVersion? {
		let result = FLTVersion()
		result.string = "iOS " + UIDevice.current.systemVersion
		return result
	}

	public func getBatteryLevelWithError(_: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> FLTBattery? {
		let result = FLTBattery()

		let device = UIDevice.current
		device.isBatteryMonitoringEnabled = true
		if device.batteryState == .unknown {
			print("=== DjiPlugin iOS Error: Host (Mobile Device) Battery info unavailable; \(device.batteryState.rawValue)")
			result.level = -1
		} else {
			print("=== DjiPlugin iOS: Host (Mobile Device) Battery level \(device.batteryLevel)")
			result.level = Int(device.batteryLevel * 100) as NSNumber
		}

		return result
	}

	public func registerAppWithError(_: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== DjiPlugin iOS: Register App Started")
		DJISDKManager.registerApp(with: self)
	}

	public func connectDroneWithError(_: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== DjiPlugin iOS: Connect Drone Started")

		//DJISDKManager.enableBridgeMode(withBridgeAppIP: "192.168.1.105")
		DJISDKManager.startConnectionToProduct()
	}

	public func disconnectDroneWithError(_: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== DjiPlugin iOS: Disconnect Drone Started")
		DJISDKManager.stopConnectionToProduct()
	}

	public func delegateDroneWithError(_: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== DjiPlugin iOS: Delegate Drone Started")
		if let product = DJISDKManager.product() {
			if product.isKind(of: DJIAircraft.self) {
				drone = (DJISDKManager.product()! as! DJIAircraft)

				if let _ = drone?.flightController {
					print("=== DjiPlugin iOS: Drone Flight Controller successfuly configured")
					drone!.flightController!.delegate = self
				} else {
					print("=== DjiPlugin iOS: Drone Flight Controller Object does not exist")
					_fltSetStatus("Error")
					return
				}

				if let _ = drone?.battery {
					print("=== DjiPlugin iOS: Drone Battery Delegate successfuly configured")
					drone!.battery!.delegate = self
				} else {
					print("=== DjiPlugin iOS: Drone Battery Delegate Error - No Battery Object")
					_fltSetStatus("Error")
					return
				}

				print("=== DjiPlugin iOS: Delegations completed")
				_fltSetStatus("Delegated")

			} else {
				print("=== DjiPlugin iOS: Error - Delegations - DJI Aircraft Object does not exist")
			}
		} else {
			print("=== DjiPlugin iOS: Error - Delegations - DJI Product Object does not exist")
		}
	}

	public func takeOffWithError(_: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneFlightController = drone?.flightController {
			print("=== DjiPlugin iOS: Takeoff Started")
			_droneFlightController.startTakeoff(completion: nil)
		} else {
			print("=== DjiPlugin iOS: Takeoff Failed - No Flight Controller")
		}
	}
	
	public func landWithError(_: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneFlightController = drone?.flightController {
			print("=== DjiPlugin iOS: Landing Started")
			_droneFlightController.startLanding(completion: nil)
		} else {
			print("=== DjiPlugin iOS: Landing Failed - No Flight Controller")
		}
	}

	public func timelineWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneFlightController = drone?.flightController {
			// First we check if a timeline is already running
			if DJISDKManager.missionControl()?.isTimelineRunning == true {
				print("=== DjiPlugin iOS: Error - Timeline already running")
				return
			} else {
				print("=== DjiPlugin iOS: Timeline Started")
			}

			guard let droneCoordinates = droneCurrentLocation?.coordinate else {
				print("=== DjiPlugin iOS: Timeline Failed - No droneCurrentLocationCoordinates")
				return
			}

			if !CLLocationCoordinate2DIsValid(droneCoordinates) {
				print("=== DjiPlugin iOS: Timeline Failed - Invalid droneCoordinates")
				return
			}

			// Set Home Coordinates
			let droneHomeLocation = CLLocation(latitude: droneCoordinates.latitude, longitude: droneCoordinates.longitude)
			let droneHomeCoordinates = droneHomeLocation.coordinate
			_droneFlightController.setHomeLocation(droneHomeLocation)
			// _droneFlightController.setHomeLocationUsingAircraftCurrentLocationWithCompletion(nil)

			var scheduledElements = [DJIMissionControlTimelineElement]()

			// Take Off
			scheduledElements.append(DJITakeOffAction())

			// Waypoint Mission
			if let wayPointMission = hardcodedWaypointMission(droneHomeCoordinates) {
				scheduledElements.append(wayPointMission)
			}

			// Hot Point
			let hotPointCoordinates = CLLocationCoordinate2DMake(droneHomeCoordinates.latitude, droneHomeCoordinates.longitude)
			if let hotPointElement = hotPointAction(hotpoint: hotPointCoordinates, altitude: 15, radius: 5) {
				scheduledElements.append(hotPointElement)
			}

			// Goto Home
			//scheduledElements.append(DJIGoHomeAction())

			// Goto Waypoint (Home)
			if let gotoElement = DJIGoToAction(coordinate: droneHomeCoordinates, altitude: 15) {
				scheduledElements.append(gotoElement)
			}

			// Land
			scheduledElements.append(DJILandAction())

			var timelineSchedulingCompleted: Bool = true
			for element in scheduledElements {
				let error = DJISDKManager.missionControl()?.scheduleElement(element)
				if error != nil {
					NSLog("=== DjiPlugin iOS: Timeline Failed - Error scheduling element \(String(describing: error))")
					timelineSchedulingCompleted = false
					return
				}
			}
			if timelineSchedulingCompleted {
				// Starting Motors
				_droneFlightController.turnOnMotors(completion: nil)

				// Starting the Timeline Mission
				DJISDKManager.missionControl()?.startTimeline()
			}

		} else {
			print("=== DjiPlugin iOS: Timeline Failed - No Flight Controller")
		}
	}

	public func startFlightJson(_ flightJson: String, error _: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== DjiPlugin iOS: Start Flight JSON: \(flightJson)")

		let decoder = JSONDecoder()
		let data = flightJson.data(using: .utf8)!
		flight = try? decoder.decode(Flight.self, from: data)

		if let f = flight {
			print("=== DjiPlugin iOS: Start Flight JSON parsed successfully: \(f)")
			startFlightTimeline(f)
		}
	}

	func startFlightTimeline(_ flight: Flight) {
		guard let timeline = flight.timeline, timeline.count > 0 else {
			print("=== DjiPlugin iOS: startFlightTimeline - timeline List is empty")
			return
		}

		guard let _droneFlightController = drone?.flightController else {
			print("=== DjiPlugin iOS: startFlightTimeline - No Flight Controller")
			return
		}

		var scheduledElements = [DJIMissionControlTimelineElement]()

		for flightElement in flight.timeline! {
			switch flightElement.type {
			case "takeOff":
				// Take Off
				scheduledElements.append(DJITakeOffAction())
				break
			
			case "land":
				// Land
				scheduledElements.append(DJILandAction())
				break
			
			case "waypointMission":
				// Waypoint Mission
				if let wayPointMission = waypointMission(flightElement) {
					scheduledElements.append(wayPointMission)
				}
				break
			
			case "hotpointAction":
				// Hot Point
				// TBD...
				break
			
			case "singleShootPhoto":
				scheduledElements.append(DJIShootPhotoAction(singleShootPhoto: ())!)
				break
				
			case "startRecordVideo":
				scheduledElements.append(DJIRecordVideoAction(startRecordVideo: ())!)
				break
				
			case "stopRecordVideo":
				scheduledElements.append(DJIRecordVideoAction(stopRecordVideo: ())!)
				break
				
			default:
				// Do Nothing
				break
			}
		}

		var timelineSchedulingCompleted: Bool = true
		for element in scheduledElements {
			let error = DJISDKManager.missionControl()?.scheduleElement(element)
			if error != nil {
				NSLog("=== DjiPlugin iOS: Timeline Failed - Error scheduling element \(String(describing: error))")
				timelineSchedulingCompleted = false
				return
			}
		}
		if timelineSchedulingCompleted {
			// Starting Motors
			_droneFlightController.turnOnMotors(completion: nil)

			// Starting the Timeline Mission
			DJISDKManager.missionControl()?.startTimeline()
		}
	}

	// MARK: - DJI Timeline Methods

	func waypointMission(_ flightElementWaypointMission: FlightElement) -> DJIWaypointMission? {
		// Waypoint Mission Initialization
		let mission = DJIMutableWaypointMission()

		if let latitude = flightElementWaypointMission.pointOfInterest?.latitude, let longitude = flightElementWaypointMission.pointOfInterest?.longitude, let altitude = flightElementWaypointMission.pointOfInterest?.altitude {
			let pointOfInteresetCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
			if CLLocationCoordinate2DIsValid(pointOfInteresetCoordinate) {
				mission.pointOfInterest = pointOfInteresetCoordinate
			}
		}
		
		mission.maxFlightSpeed = Float(flightElementWaypointMission.maxFlightSpeed ?? 15)
		mission.autoFlightSpeed = Float(flightElementWaypointMission.autoFlightSpeed ?? 8)

		switch flightElementWaypointMission.finishedAction {
		case "autoLand":
			mission.finishedAction = .autoLand
		case "continueUntilStop":
			mission.finishedAction = .continueUntilStop
		default:
			mission.finishedAction = .noAction
		}

		switch flightElementWaypointMission.headingMode {
		case "auto":
			mission.headingMode = .auto
		case "towardPointOfInterest":
			mission.headingMode = .towardPointOfInterest
		default:
			mission.headingMode = .usingWaypointHeading
		}

		switch flightElementWaypointMission.flightPathMode {
		case "normal":
			mission.flightPathMode = .normal
		default:
			mission.flightPathMode = .curved
		}

		mission.rotateGimbalPitch = flightElementWaypointMission.rotateGimbalPitch ?? true
		mission.exitMissionOnRCSignalLost = flightElementWaypointMission.exitMissionOnRCSignalLost ?? true

		mission.gotoFirstWaypointMode = .pointToPoint
		mission.repeatTimes = 1

		// Waypoints
		if let flightWaypoints = flightElementWaypointMission.waypoints {
			for flightWaypoint in flightWaypoints {
				if let latitude = flightWaypoint.location?.latitude, let longitude = flightWaypoint.location?.longitude, let altitude = flightWaypoint.location?.altitude {
					let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
					let waypoint = DJIWaypoint(coordinate: coordinate)
					waypoint.altitude = Float(altitude)
					waypoint.heading = flightWaypoint.heading ?? 0
					waypoint.cornerRadiusInMeters = flightWaypoint.cornerRadiusInMeters != nil ? Float(flightWaypoint.cornerRadiusInMeters!) : 5
					switch flightWaypoint.turnMode {
					case "counterClockwise":
						waypoint.turnMode = .counterClockwise
					default:
						waypoint.turnMode = .clockwise
					}
					waypoint.gimbalPitch = flightWaypoint.gimbalPitch != nil ? Float(flightWaypoint.gimbalPitch!) : 0
					waypoint.actionTimeoutInSeconds = 30
					waypoint.actionRepeatTimes = 1

					mission.add(waypoint)
				} else {
					print("=== DjiPlugin iOS: waypointMission - waypoint without location coordinates - skipping")
				}
			}
			return DJIWaypointMission(mission: mission)
		} else {
			print("=== DjiPlugin iOS: waypointMission - No waypoints available - exiting")
			return nil
		}
	}

	func hardcodedWaypointMission(_ droneCoordinates: CLLocationCoordinate2D) -> DJIWaypointMission? {
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
		// waypoint1.heading = 0
		waypoint1.actionRepeatTimes = 1
		waypoint1.actionTimeoutInSeconds = 30
		waypoint1.cornerRadiusInMeters = 5
		waypoint1.turnMode = .clockwise
		waypoint1.gimbalPitch = -30

		let loc3 = CLLocationCoordinate2DMake(droneCoordinates.latitude, droneCoordinates.longitude + (offset * 5))
		let waypoint3 = DJIWaypoint(coordinate: loc3)
		waypoint2.altitude = 15
		// waypoint2.heading = 0
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

	func hotPointAction(hotpoint: CLLocationCoordinate2D, altitude: Float, radius: Float) -> DJIHotpointAction? {
		if !CLLocationCoordinate2DIsValid(hotpoint) {
			return nil
		}

		let mission = DJIHotpointMission()

		mission.hotpoint = hotpoint
		mission.altitude = altitude
		mission.radius = radius
		DJIHotpointMissionOperator.getMaxAngularVelocity(forRadius: Double(mission.radius), withCompletion: { (velocity: Float, _: Error?) in
			mission.angularVelocity = velocity
		})
		mission.startPoint = .nearest
		mission.heading = .towardHotpoint

		return DJIHotpointAction(mission: mission, surroundingAngle: 180)
	}
	
	// MARK: - Playback Manager Methods
	
	public func downloadAllMediaWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneCamera = drone?.camera {
			_droneCamera.setMode(DJICameraMode.mediaDownload, withCompletion: { (error: Error?) in
				if (error != nil) {
					print("=== DjiPlugin iOS: Download all media failed with error - \(String(describing: error?.localizedDescription))")
					self._fltSetStatus("Download Failed")
				} else {
					print("=== DjiPlugin iOS: Download all media started")
					self._fltSetStatus("Download Started")
					
					if let _droneMediaManager = _droneCamera.mediaManager {
						// Fetching the Media List and grabbing the lastest media file
						if _droneMediaManager.sdCardFileListState == DJIMediaFileListState.syncing ||
						   _droneMediaManager.sdCardFileListState == DJIMediaFileListState.deleting {
							print("=== DjiPlugin iOS: Download Failed - Media Manager is busy")
						} else {
							_droneMediaManager.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: {[weak self] (e: Error?) in
								if let error = e {
									print("=== DjiPlugin iOS: Fetch Media File List Failed: %@", error.localizedDescription)
								} else {
									if let mediaFileList = _droneMediaManager.sdCardFileListSnapshot() {
										print("=== DjiPlugin iOS: Fetch Media File List Success")
										
										// Selecting the last media file
										if let selectedMedia = mediaFileList.last {
											let isPhoto = selectedMedia.mediaType == DJIMediaType.JPEG || selectedMedia.mediaType == DJIMediaType.TIFF
										
											var previousOffset = UInt(0)
											var fileData : Data?
											selectedMedia.fetchData(withOffset: previousOffset, update: DispatchQueue.main, update: {[weak self] (data:Data?, isComplete: Bool, e: Error?) in
												if let error = e {
													print("=== DjiPlugin iOS: Fetch Data: %@", error.localizedDescription)
													self?._fltSetStatus("Download Failed")
												} else {
													if let data = data {
														if fileData == nil {
															fileData = data
														} else {
															fileData?.append(data)
														}
														
														if (isPhoto == false) {
															previousOffset = previousOffset + UInt(data.count)
														}
													}
													
													let selectedFileSizeBytes = selectedMedia.fileSizeInBytes
													let progress = Float(previousOffset) * 100.0 / Float(selectedFileSizeBytes)
													
													self?._fltSetStatus(String(format: "%0.1f%%", progress))
													
													if (isComplete == true) {
														
														let tmpDir = NSTemporaryDirectory() as NSString
														let tmpMediaFilePath = tmpDir.appendingPathComponent(isPhoto ? "image.jpg" : "video.mp4")
														let url = URL(fileURLWithPath: tmpMediaFilePath)
														
														do {
															try fileData?.write(to: url)
														} catch {
															print("=== DjiPlugin iOS: Failed to write data to file: \(error)")
															self?._fltSetStatus("Download Failed")
														}
														
														guard let mediaURL = URL(string: tmpMediaFilePath) else {
															print("=== DjiPlugin iOS: Failed to load a filepath to save to")
															self?._fltSetStatus("Download Failed")
															return
														}
														
														print("=== DjiPlugin iOS: Download media completed: %@", mediaURL.absoluteString)
														self?._fltSetStatus("Downloaded")
														
//														return mediaURL.absoluteString
														
														// Saving the media to the Photo Gallery
														PHPhotoLibrary.shared().performChanges {
															if (isPhoto) {
																PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: mediaURL)
															} else {
																PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: mediaURL)
															}
														} completionHandler: { (success:Bool, e: Error?) in
															if (success == true) {
																print("=== DjiPlugin iOS: Successfully saved media to gallery")

																print("=== DjiPlugin iOS: Download media completed")
																self?._fltSetStatus("Downloaded")

															} else if let error = e {
																print("=== DjiPlugin iOS: Failed to save media to gallery %@: ", error.localizedDescription)
																self?._fltSetStatus("Download Failed")
															}
														}
													}
												}
											})
										} else {
											print("=== DjiPlugin iOS: SD Card File List Snapshot Failed")
											return;
										}
									}
								}
							})
						}
					} else {
						print("=== DjiPlugin iOS: Download media failed - no Media Manager")
						self._fltSetStatus("Download Failed")
					}
				}
			})
		} else {
			print("=== DjiPlugin iOS: Download all media failed - no Camera object")
			_fltSetStatus("Download Failed")
		}
	}
	
	public func deleteAllMediaWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneCamera = drone?.camera {
			_droneCamera.setMode(DJICameraMode.mediaDownload, withCompletion: { (error: Error?) in
				if (error != nil) {
					print("=== DjiPlugin iOS: Delete all media failed with error - \(String(describing: error?.localizedDescription))")
					self._fltSetStatus("Delete Failed")
				} else {
					print("=== DjiPlugin iOS: Delete all media started")
					self._fltSetStatus("Delete Started")
					
					if let _dronePlayBackManager = _droneCamera.playbackManager {
						_dronePlayBackManager.selectAllFiles()
						_dronePlayBackManager.deleteAllSelectedFiles()
						
						print("=== DjiPlugin iOS: Delete all media completed")
						
						self._fltSetStatus("Deleted")
					} else {
						print("=== DjiPlugin iOS: Delete all media failed - no Playback Manager")
						self._fltSetStatus("Delete Failed")
					}
				}
			})
		} else {
			print("=== DjiPlugin iOS: Delete all media failed - no Camera object")
			_fltSetStatus("Delete Failed")
		}
	}

	// MARK: - DJISDKManager Delegate Methods

	public func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
		print("Downloading database: \(progress.completedUnitCount) / \(progress.totalUnitCount)")
	}

	public func appRegisteredWithError(_ error: Error?) {
		if error != nil {
			print("=== DjiPlugin iOS: Error: Register app failed! Please enter your app key and check the network.")
		} else {
			print("=== DjiPlugin iOS: Register App Successed!")
			_fltSetStatus("Registered")
		}
	}

	public func productConnected(_ product: DJIBaseProduct?) {
		// DJI Product is available only after registration and connection. So we initialize it here.
		if let _ = product {
			print("=== DjiPlugin iOS: Product Connected successfuly")
			_fltSetStatus("Connected")
		} else {
			print("=== DjiPlugin iOS: Error Connecting Product - DJIBaseProduct does not exist")
		}
	}

	public func productDisconnected() {
		print("=== DjiPlugin iOS: Product Disconnected")
		_fltSetStatus("Disconnected")
	}

	// MARK: - DJIBattery Delegate Methods

	public func battery(_: DJIBattery, didUpdate state: DJIBatteryState) {
		// Updating Flutter
		fltDrone.batteryPercent = Double(state.chargeRemainingInPercent) as NSNumber
		// print("=== DjiPlugin iOS: Battery Percent \(fltDrone.batteryPercent ?? 0)%")

		SwiftDjiPlugin.fltDjiFlutterApi?.setStatusDrone(fltDrone) { e in
			if let error = e {
				print("=== DjiPlugin iOS: Error: SetStatus Closure Error")
				NSLog("error: %@", error.localizedDescription)
			}
		}
	}

	// MARK: - DJIFlightController Delegate Methods

	public func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
		var _droneLatitude: NSNumber = 0
		var _droneLongitude: NSNumber = 0
		var _droneAltitude: NSNumber = 0
		var _droneSpeed: NSNumber = 0
		var _droneRoll: NSNumber = 0
		var _dronePitch: NSNumber = 0
		var _droneYaw: NSNumber = 0

		if let altitude = state.aircraftLocation?.altitude {
			// print("= iOS: Altitude - \(altitude)")
			_droneAltitude = altitude as NSNumber
		}

		// Updating the drone's current location coordinates variable
		if let droneLocation = state.aircraftLocation {
			droneCurrentLocation = droneLocation
		}

		if let latitude = state.aircraftLocation?.coordinate.latitude {
			// print("= iOS: Latitude - \(latitude)")
			_droneLatitude = latitude as NSNumber
		}

		if let longitude = state.aircraftLocation?.coordinate.longitude {
			// print("= iOS: Longitude - \(longitude)")
			_droneLongitude = longitude as NSNumber
		}

		if let speed = state.aircraftLocation?.speed {
			// print("= iOS: Speed - \(speed)")
			_droneSpeed = speed as NSNumber
		}

		// print("= iOS: Roll \(state.attitude.roll) | Pitch \(state.attitude.pitch) | Yaw \(state.attitude.yaw)")
		_droneRoll = state.attitude.roll as NSNumber
		_dronePitch = state.attitude.pitch as NSNumber
		_droneYaw = state.attitude.yaw as NSNumber

		// Confirm Landing
		if state.isLandingConfirmationNeeded == true {
			fc.confirmLanding(completion: nil)
		}

		// Updating Flutter
		fltDrone.latitude = _droneLatitude
		fltDrone.longitude = _droneLongitude
		fltDrone.altitude = _droneAltitude
		fltDrone.speed = _droneSpeed
		fltDrone.roll = _droneRoll
		fltDrone.pitch = _dronePitch
		fltDrone.yaw = _droneYaw

		SwiftDjiPlugin.fltDjiFlutterApi?.setStatusDrone(fltDrone) { e in
			if let error = e {
				print("=== DjiPlugin iOS: Error: SetStatus Closure Error")
				NSLog("error: %@", error.localizedDescription)
			}
		}
	}

	// MARK: - Flight Struct

	struct Flight: Codable {
		var timeline: [FlightElement]?

		enum CodingKeys: String, CodingKey {
			case timeline
		}

		init(from decoder: Decoder) throws {
			let values = try decoder.container(keyedBy: CodingKeys.self)

			timeline = try values.decodeIfPresent([FlightElement].self, forKey: .timeline)
		}
	}

	struct FlightElement: Codable {
		var type: String?
		var pointOfInterest: FlightLocation?
		var maxFlightSpeed: Double?
		var autoFlightSpeed: Double?
		var finishedAction: String?
		var headingMode: String?
		var flightPathMode: String?
		var rotateGimbalPitch: Bool?
		var exitMissionOnRCSignalLost: Bool?
		var waypoints: [FlightWaypoint]?

		enum CodingKeys: String, CodingKey {
			case type, pointOfInterest, maxFlightSpeed, autoFlightSpeed, finishedAction, headingMode, flightPathMode, rotateGimbalPitch, exitMissionOnRCSignalLost, waypoints
		}

		init(from decoder: Decoder) throws {
			let values = try decoder.container(keyedBy: CodingKeys.self)

			type = try values.decodeIfPresent(String.self, forKey: .type)
			pointOfInterest = try values.decodeIfPresent(FlightLocation.self, forKey: .pointOfInterest)
			autoFlightSpeed = try values.decodeIfPresent(Double.self, forKey: .autoFlightSpeed)
			maxFlightSpeed = try values.decodeIfPresent(Double.self, forKey: .maxFlightSpeed)
			exitMissionOnRCSignalLost = try values.decodeIfPresent(Bool.self, forKey: .exitMissionOnRCSignalLost)
			finishedAction = try values.decodeIfPresent(String.self, forKey: .finishedAction)
			flightPathMode = try values.decodeIfPresent(String.self, forKey: .flightPathMode)
			headingMode = try values.decodeIfPresent(String.self, forKey: .headingMode)
			rotateGimbalPitch = try values.decodeIfPresent(Bool.self, forKey: .rotateGimbalPitch)
			waypoints = try values.decodeIfPresent([FlightWaypoint].self, forKey: .waypoints)
		}
	}

	struct FlightLocation: Codable {
		var latitude: Double?
		var longitude: Double?
		var altitude: Double?

		enum CodingKeys: String, CodingKey {
			case latitude, longitude, altitude
		}

		init(from decoder: Decoder) throws {
			let values = try decoder.container(keyedBy: CodingKeys.self)

			latitude = try values.decodeIfPresent(Double.self, forKey: .latitude)
			longitude = try values.decodeIfPresent(Double.self, forKey: .longitude)
			altitude = try values.decodeIfPresent(Double.self, forKey: .altitude)
		}
	}

	struct FlightWaypoint: Codable {
		var location: FlightLocation?
		var heading: Int?
		var cornerRadiusInMeters: Double?
		var turnMode: String?
		var gimbalPitch: Double?

		enum CodingKeys: String, CodingKey {
			case location, heading, cornerRadiusInMeters, turnMode, gimbalPitch
		}

		init(from decoder: Decoder) throws {
			let values = try decoder.container(keyedBy: CodingKeys.self)

			location = try values.decodeIfPresent(FlightLocation.self, forKey: .location)
			heading = try values.decodeIfPresent(Int.self, forKey: .heading)
			cornerRadiusInMeters = try values.decodeIfPresent(Double.self, forKey: .cornerRadiusInMeters)
			turnMode = try values.decodeIfPresent(String.self, forKey: .turnMode)
			gimbalPitch = try values.decodeIfPresent(Double.self, forKey: .gimbalPitch)
		}
	}
}
