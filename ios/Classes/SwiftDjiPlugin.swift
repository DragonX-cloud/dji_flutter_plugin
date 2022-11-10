import Foundation
import DJISDK
import DJIWidget
import Flutter
import UIKit

public class SwiftDjiPlugin: FLTDjiFlutterApi, FlutterPlugin, FLTDjiHostApi, DJISDKManagerDelegate, DJIFlightControllerDelegate, DJIBatteryDelegate, DJIVideoFeedListener, VideoFrameProcessor {
	
	static var fltDjiFlutterApi: FLTDjiFlutterApi?
	let fltDrone = FLTDrone()
	let fltStream = FLTStream()
	
	var drone: DJIAircraft?
	var droneCurrentLocation: CLLocation?
	var mediaFileList = [DJIMediaFile?]()
	var videoFeedUrl: URL?
	var videoFeedPath: String?
	var videoFeedFileData: Data?

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
				NSLog("error: \(error.localizedDescription)")
			} else {
				print("=== DjiPlugin iOS: setStatus Closure Success: \(status)")
			}
		}
	}

	private func _fltSetError(_ error: String) {
		fltDrone.error = error

		SwiftDjiPlugin.fltDjiFlutterApi?.setStatusDrone(fltDrone) { e in
			if let error = e {
				print("=== DjiPlugin iOS: Error: SetStatus (setting drone error) Closure Error")
				NSLog("error: \(error.localizedDescription)")
			} else {
				print("=== DjiPlugin iOS: setStatus (setting drone error) Closure Success: \(error)")
			}
		}
	}
	
	private func _fltSendVideo(_ data: Data) {
		fltStream.data = FlutterStandardTypedData(bytes: data)
		
		SwiftDjiPlugin.fltDjiFlutterApi?.sendVideoStream(fltStream) { e in
			if let error = e {
				print("=== DjiPlugin iOS: Error: sendVideo Closure Error")
				NSLog("error: \(error.localizedDescription)")
			}
		}
	}

	// MARK: - Basic Methods

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
					_fltSetError("Drone Flight Controller Object does not exist")
					return
				}

				if let _ = drone?.battery {
					print("=== DjiPlugin iOS: Drone Battery Delegate successfuly configured")
					drone!.battery!.delegate = self
				} else {
					print("=== DjiPlugin iOS: Drone Battery Delegate Error - No Battery Object")
					_fltSetStatus("Error")
					_fltSetError("Drone Battery Delegate Error - No Battery Object")
					return
				}

				print("=== DjiPlugin iOS: Delegations completed")
				_fltSetStatus("Delegated")
				_fltSetError("")

			} else {
				print("=== DjiPlugin iOS: Error - Delegations - DJI Aircraft Object does not exist")
				_fltSetStatus("Error")
				_fltSetError("Delegations - DJI Aircraft Object does not exist")
			}
		} else {
			print("=== DjiPlugin iOS: Error - Delegations - DJI Product Object does not exist")
			_fltSetStatus("Error")
			_fltSetError("Delegations - DJI Product Object does not exist")
		}
	}

	public func takeOffWithError(_: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneFlightController = drone?.flightController {
			print("=== DjiPlugin iOS: Takeoff Started")
			_fltSetStatus("Takeoff")
			_fltSetError("")
			_droneFlightController.startTakeoff(completion: nil)
		} else {
			print("=== DjiPlugin iOS: Takeoff Failed - No Flight Controller")
			_fltSetStatus("Takeoff Failed")
			_fltSetError("Takeoff Failed - No Flight Controller")
		}
	}
	
	public func landWithError(_: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneFlightController = drone?.flightController {
			print("=== DjiPlugin iOS: Landing Started")
			_fltSetStatus("Land")
			_fltSetError("")
			_droneFlightController.startLanding(completion: nil)
		} else {
			print("=== DjiPlugin iOS: Landing Failed - No Flight Controller")
			_fltSetStatus("Land Failed")
			_fltSetError("Landing Failed - No Flight Controller")
		}
	}
	
	// MARK: - Mobile Remote Controller
	
	public func mobileRemoteControllerEnabled(_ enabled: NSNumber, leftStickHorizontal: NSNumber, leftStickVertical: NSNumber, rightStickHorizontal: NSNumber, rightStickVertical: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		// the `enabled` property is redundant at this point, but it's here as a placeholder for possible usage in the future.
		
		if (drone?.mobileRemoteController?.isConnected == true) {
			drone?.mobileRemoteController?.leftStickHorizontal = Float(truncating: leftStickHorizontal)
			drone?.mobileRemoteController?.leftStickVertical = Float(truncating: leftStickVertical)
			drone?.mobileRemoteController?.rightStickHorizontal = Float(truncating: rightStickHorizontal)
			drone?.mobileRemoteController?.rightStickVertical = Float(truncating: rightStickVertical)
			self._fltSetStatus("Mobile Remote")
			self._fltSetError("")
		} else {
			print("=== DjiPlugin iOS: Mobile Remote - isConnected FALSE")
			self._fltSetStatus("Mobile Remote Failed")
			self._fltSetError("Mobile Remote - isConnected FALSE")
		}
	}
	
	// MARK: - Virtual Stick Methods
	
	public func virtualStickEnabled(_ enabled: NSNumber, pitch: NSNumber, roll: NSNumber, yaw: NSNumber, verticalThrottle: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		var virtualStickControlData: DJIVirtualStickFlightControlData = DJIVirtualStickFlightControlData()
		
        guard let _droneFlightController = drone?.flightController else {
			print("=== DjiPlugin iOS: Virtual Stick - No Flight Controller")
			_fltSetStatus("Virtual Stick Failed")
			_fltSetError("Virtual Stick - No Flight Controller")
			return
		}
		
		_droneFlightController.setVirtualStickModeEnabled(enabled as! Bool, withCompletion: { (error: Error?) in
			if (error != nil) {
				print("=== DjiPlugin iOS: Enable Virtual Stick failed with error - \(String(describing: error?.localizedDescription))")
				self._fltSetStatus("Virtual Stick Failed")
				self._fltSetError("Enable Virtual Stick failed with error - \(String(describing: error?.localizedDescription))")
			} else {
				virtualStickControlData.pitch = Float(truncating: pitch)
				virtualStickControlData.roll = Float(truncating: roll)
				virtualStickControlData.yaw = Float(truncating: yaw)
				virtualStickControlData.verticalThrottle = Float(truncating: verticalThrottle)

				// Setting the drone's flight control parameters for easy Virtual Stick usage
				_droneFlightController.setFlightOrientationMode(DJIFlightOrientationMode.aircraftHeading) // Mandatory for Virtual Stick Control Mode to be available.
				//_droneFlightController.isVirtualStickAdvancedModeEnabled = true
				_droneFlightController.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystem.body
				_droneFlightController.rollPitchControlMode = DJIVirtualStickRollPitchControlMode.angle
				_droneFlightController.yawControlMode = DJIVirtualStickYawControlMode.angle
				_droneFlightController.verticalControlMode = DJIVirtualStickVerticalControlMode.position
				
				if (_droneFlightController.isVirtualStickControlModeAvailable() == false) {
					print("=== DjiPlugin iOS: Virtual Stick control mode is not available")
					self._fltSetStatus("Virtual Stick Failed")
					self._fltSetError("Virtual Stick control mode is not available")
					return
				} else {
					//print("=== DjiPlugin iOS: updateVirtualSticks - mThrottle: TBD...")
					_droneFlightController.send(virtualStickControlData, withCompletion: { (error: Error?) in
						if (error != nil) {
							print("=== DjiPlugin iOS: Virtual Stick send failed with error - \(String(describing: error?.localizedDescription))")
							self._fltSetStatus("Virtual Stick Failed")
							self._fltSetError("Virtual Stick send failed with error - \(String(describing: error?.localizedDescription))")
						} else {
							self._fltSetStatus("Virtual Stick")
							self._fltSetError("")
						}
					})
				}
			}
		})
	}
	
	// MARK: - Gimbal Methods
	
	public func gimbalRotatePitchDegrees(_ degrees: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if (drone?.gimbal?.isConnected == true) {
			//drone?.gimbal?.setMode(DJIGimbalMode.yawFollow)
			
			let djiGimbalRotation = DJIGimbalRotation.init(pitchValue: degrees, rollValue: nil, yawValue: nil, time: 1.0 as TimeInterval, mode: .absoluteAngle, ignore: true)
			drone?.gimbal?.rotate(with: djiGimbalRotation, completion: { (error: Error?) in
				if (error != nil) {
					print("=== DjiPlugin iOS: Gimbal Rotate failed with error - \(String(describing: error?.localizedDescription))")
					self._fltSetStatus("Gimbal Failed")
					self._fltSetError("Gimbal Rotate failed with error - \(String(describing: error?.localizedDescription))")
				} else {
					self._fltSetStatus("Gimbal Rotated")
					self._fltSetError("")
				}
			})
		} else {
			print("=== DjiPlugin iOS: Gimbal - isConnected FALSE")
			self._fltSetStatus("Gimbal Failed")
			self._fltSetError("Gimbal - isConnected FALSE")
		}
	}
	
	// MARK: - Timeline Methods

	public func startFlightJson(_ flightJson: String, error _: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== DjiPlugin iOS: Start Flight JSON: \(flightJson)")

		let decoder = JSONDecoder()
		let data = flightJson.data(using: .utf8)!
		
		if let f = try? decoder.decode(Flight.self, from: data) {
			print("=== DjiPlugin iOS: Start Flight JSON parsed successfully: \(f)")
			startFlightTimeline(f)
		}
	}
	
	func startFlightTimeline(_ flight: Flight) {
		guard let timeline = flight.timeline, timeline.count > 0 else {
			print("=== DjiPlugin iOS: startFlightTimeline failed - Timeline List is empty")
			_fltSetError("Start Failed")
			_fltSetError("startFlightTimeline failed - Timeline List is empty")
			return
		}

		guard let _droneFlightController = drone?.flightController else {
			print("=== DjiPlugin iOS: startFlightTimeline failed - No Flight Controller")
			_fltSetError("Start Failed")
			_fltSetError("startFlightTimeline failed - No Flight Controller")
			return
		}
		
		if (DJISDKManager.missionControl()?.isTimelineRunning == true) {
			print("=== DjiPlugin iOS: startFlightTimeline failed - Timeline already running - attempting to stop it")
			_fltSetError("Start Failed")
			_fltSetError("startFlightTimeline failed - Timeline already running - attempting to stop it")
			DJISDKManager.missionControl()?.stopTimeline()
			return
		}
		
		// Set Home Location Coordinates
		if let currentLocation = droneCurrentLocation {
			_droneFlightController.setHomeLocation(currentLocation)
			
			print("=== DjiPlugin iOS: startFlightTimeline - Drone Home Location Coordinates: \(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
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
		
		if let _missionControl = DJISDKManager.missionControl() {
			// Making sure the MissionControl Timeline is clean
			_missionControl.unscheduleEverything()
			
			// Listening for DJI Mission Control errors
			_missionControl.removeAllListeners()
			_missionControl.addListener(self, toTimelineProgressWith: { (event: DJIMissionControlTimelineEvent, element: DJIMissionControlTimelineElement?, e: Error?, info: Any?) in
				if let error = e {
					print("=== DjiPlugin iOS: Mission Control Error - \(error.localizedDescription)")
					self._fltSetStatus("Start Failed")
					self._fltSetError("Mission Control Error - \(error.localizedDescription)")
				}
			})
			
			// Adding the scheduled elements
			var timelineSchedulingCompleted: Bool = true
			for element in scheduledElements {
				let error = _missionControl.scheduleElement(element)
				if error != nil {
					print("=== DjiPlugin iOS: Timeline Failed - Error scheduling element \(String(describing: error))")
					_fltSetStatus("Start Failed")
					_fltSetError("Timeline Failed - Error scheduling element \(String(describing: error))")
					timelineSchedulingCompleted = false
					return
				}
			}
			if timelineSchedulingCompleted {
				// Starting Motors
				// _droneFlightController.turnOnMotors(completion: nil)

				// Starting the Timeline Mission
				_missionControl.startTimeline()
				
				_fltSetStatus("Started")
				_fltSetError("")
			}
		} else {
			print("=== DjiPlugin iOS: startFlightTimeline - No Mission Control or Scheduled Elements")
			_fltSetStatus("Start Failed")
			_fltSetError("startFlightTimeline - No Mission Control or Scheduled Elements")
		}
	}

	// MARK: - Waypoint Methods

	func waypointMission(_ flightElementWaypointMission: FlightElement) -> DJIWaypointMission? {
		// Waypoint Mission Initialization
		let mission = DJIMutableWaypointMission()

		if let latitude = flightElementWaypointMission.pointOfInterest?.latitude, let longitude = flightElementWaypointMission.pointOfInterest?.longitude {
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
			self._fltSetStatus("Error")
			self._fltSetError("waypointMission - No waypoints available - exiting")
			return nil
		}
	}
	
	// MARK: - Media Methods
	
	public func getMediaListWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> [FLTMedia]? {
		var _fltMediaList = [FLTMedia]()
		
		if let _droneCamera = drone?.camera {
			_droneCamera.setMode(DJICameraMode.mediaDownload, withCompletion: { (error: Error?) in
				if (error != nil) {
					print("=== DjiPlugin iOS: Get media list - set camera mode failed with error - \(String(describing: error?.localizedDescription))")
					self._fltSetStatus("Media List Failed")
					self._fltSetError("Get media list - set camera mode failed with error - \(String(describing: error?.localizedDescription))")
				} else {
					print("=== DjiPlugin iOS: Get media list started")
					
					if let _droneMediaManager = _droneCamera.mediaManager {
						// Fetching the Media List from the Drone's SD Card
						if _droneMediaManager.sdCardFileListState == DJIMediaFileListState.syncing ||
						   _droneMediaManager.sdCardFileListState == DJIMediaFileListState.deleting {
							print("=== DjiPlugin iOS: Get media list failed - Media Manager is busy")
							self._fltSetStatus("Media List Failed")
							self._fltSetError("Get media list failed - Media Manager is busy")
						} else {
							_droneMediaManager.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: {[weak self] (e: Error?) in
								if let error = e {
									print("=== DjiPlugin iOS: Get media list failed: \(error.localizedDescription)")
									self?._fltSetStatus("Media List Failed")
									self?._fltSetError("Get media list failed: \(error.localizedDescription)")
								} else {
									if let sdCardMediaFileList = _droneMediaManager.sdCardFileListSnapshot() {
										print("=== DjiPlugin iOS: Get media list successful")
										self?._fltSetStatus("Got Media List")
										self?._fltSetError("")
										
										self?.mediaFileList = sdCardMediaFileList
										
										// Preparing the Flutter Media List
										for mediaFile in sdCardMediaFileList {
											let fltMediaListElement = FLTMedia()
											fltMediaListElement.fileName = mediaFile.fileName
											fltMediaListElement.fileIndex = mediaFile.index as NSNumber
											
											_fltMediaList.append(fltMediaListElement)
											
											print("=== DjiPlugin iOS: Get media list - added file \(mediaFile.fileName)")
										}
									} else {
										print("=== DjiPlugin iOS: Get media list failed - list is empty")
										self?._fltSetStatus("Get Media Failed")
										self?._fltSetError("Get media list failed - list is empty")
									}
								}
							})
						}
					} else {
						print("=== DjiPlugin iOS: Get media list - no Media Manager")
						self._fltSetStatus("Media List Failed")
						self._fltSetError("Get media list - no Media Manager")
					}
				}
			})
		} else {
			print("=== DjiPlugin iOS: Get media list - no Camera object")
			_fltSetStatus("Media List Failed")
			_fltSetError("Get media list - no Camera object")
		}
		
		return _fltMediaList
	}
	
	public func downloadMediaFileIndex(_ fileIndex: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> String? {
		var _mediaURLString: String = ""
		let _index: Int = fileIndex.intValue

		guard _index >= 0 else {
			print("=== DjiPlugin iOS: Download media failed - invalid index")
			_fltSetStatus("Download Failed")
			_fltSetError("Download media failed - invalid index")

			return ""
		}

		guard !mediaFileList.isEmpty else {
			print("=== DjiPlugin iOS: Download media failed - list is empty")
			_fltSetStatus("Download Failed")
			_fltSetError("Download media failed - list is empty")

			return ""
		}

		if let _droneCamera = drone?.camera {
			_droneCamera.setMode(DJICameraMode.mediaDownload, withCompletion: { (error: Error?) in
				if (error != nil) {
					print("=== DjiPlugin iOS: Download media - set camera mode failed with error - \(String(describing: error?.localizedDescription))")
					self._fltSetStatus("Download Failed")
					self._fltSetError("Download media - set camera mode failed with error - \(String(describing: error?.localizedDescription))")
				} else {
					print("=== DjiPlugin iOS: Download media started")
					self._fltSetStatus("Download Started")
					self._fltSetError("")

					if let selectedMedia = self.mediaFileList[_index] {
						let isPhoto = selectedMedia.mediaType == DJIMediaType.JPEG || selectedMedia.mediaType == DJIMediaType.TIFF
						var previousOffset = UInt(0)
						var fileData: Data?

						selectedMedia.fetchData(withOffset: previousOffset, update: DispatchQueue.main, update: {[weak self] (data:Data?, isComplete: Bool, e: Error?) in
							if let error = e {
								print("=== DjiPlugin iOS: Download media failed - Fetch File Data: \(error.localizedDescription)")
								self?._fltSetStatus("Download Failed")
								self?._fltSetError("Download media failed - Fetch File Data: \(error.localizedDescription)")
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
								self?._fltSetError("")

								if (isComplete == true) {

									let tmpDir = NSTemporaryDirectory() as NSString
									let tmpMediaFilePath = tmpDir.appendingPathComponent(isPhoto ? "image.jpg" : "video.mp4")
									let url = URL(fileURLWithPath: tmpMediaFilePath)

									do {
										try fileData?.write(to: url)
									} catch {
										print("=== DjiPlugin iOS: Download failed to write data to file: \(error)")
										self?._fltSetStatus("Download Failed")
										self?._fltSetError("Download failed to write data to file: \(error)")
									}

									guard let mediaURL = URL(string: tmpMediaFilePath) else {
										print("=== DjiPlugin iOS: Download failed to load a filepath to save to")
										self?._fltSetStatus("Download Failed")
										self?._fltSetError("Download failed to load a filepath to save to")
										return
									}

									print("=== DjiPlugin iOS: Download media completed: \(mediaURL.absoluteString)")
									self?._fltSetStatus("Downloaded")
									self?._fltSetError("")

									_mediaURLString = mediaURL.absoluteString

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
											self?._fltSetError("")

										} else if let error = e {
											print("=== DjiPlugin iOS: Download failed to save media to gallery - \(error.localizedDescription)")
											self?._fltSetStatus("Download Failed")
											self?._fltSetError("Download failed to save media to gallery - \(error.localizedDescription)")
										}
									}
								}
							}
						})
					} else {
						print("=== DjiPlugin iOS: Download media - file not found")
						self._fltSetStatus("Download Failed")
						self._fltSetError("Download media - file not found")
					}
				}
			})
		} else {
			print("=== DjiPlugin iOS: Download all media failed - no Camera object")
			_fltSetStatus("Download Failed")
			_fltSetError("Download all media failed - no Camera object")
		}

		return _mediaURLString
	}
	
	public func deleteMediaFileIndex(_ fileIndex: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
		var _success: Bool = false
		let _index: Int = fileIndex.intValue
		
		guard _index >= 0 else {
			print("=== DjiPlugin iOS: Delete media failed - invalid index")
			_fltSetStatus("Delete Failed")
			_fltSetError("Delete media failed - invalid index")
			
			return nil
		}
		
		guard !mediaFileList.isEmpty else {
			print("=== DjiPlugin iOS: Delete media failed - list is empty")
			_fltSetStatus("Delete Failed")
			_fltSetError("Delete media failed - list is empty")
			
			return nil
		}
		
		if let _droneCamera = drone?.camera {
			_droneCamera.setMode(DJICameraMode.mediaDownload, withCompletion: { (error: Error?) in
				if (error != nil) {
					print("=== DjiPlugin iOS: Delete media failed with error - \(String(describing: error?.localizedDescription))")
					self._fltSetStatus("Delete Failed")
					self._fltSetError("Delete media failed with error - \(String(describing: error?.localizedDescription))")
				} else {
					print("=== DjiPlugin iOS: Delete media started")
					self._fltSetStatus("Delete Started")
					self._fltSetError("")
					
					if let _droneMediaManager = _droneCamera.mediaManager {
						if let selectedMedia = self.mediaFileList[_index] {
							_droneMediaManager.delete([selectedMedia])
							
							print("=== DjiPlugin iOS: Delete media completed")
							self._fltSetStatus("Deleted")
							self._fltSetError("")
							_success = true
						} else {
							print("=== DjiPlugin iOS: Delete media - file not found")
							self._fltSetStatus("Delete Failed")
							self._fltSetError("Delete media - file not found")
							_success = false
						}
					} else {
						print("=== DjiPlugin iOS: Delete media failed - no Playback Manager")
						
						self._fltSetStatus("Delete Failed")
						self._fltSetError("Delete media failed - no Playback Manager")
						_success = false
					}
				}
			})
		} else {
			print("=== DjiPlugin iOS: Delete all media failed - no Camera object")
			_fltSetStatus("Delete Failed")
			_fltSetError("Delete all media failed - no Camera object")
			_success = false
		}
		
		return _success as NSNumber
	}
	
	// MARK: - Video Feed Methods
	
	public func videoFeedStartWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneCamera = drone?.camera {
			_droneCamera.setMode(DJICameraMode.recordVideo, withCompletion: { (error: Error?) in
				if (error != nil) {
					print("=== DjiPlugin iOS: Video feed start failed with error - \(String(describing: error?.localizedDescription))")
					self._fltSetStatus("Video Start Failed")
					self._fltSetError("Video feed start failed with error - \(String(describing: error?.localizedDescription))")
				} else {
					DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
		
					DJIVideoPreviewer.instance().type = .none
					DJIVideoPreviewer.instance().enableHardwareDecode = true
					DJIVideoPreviewer.instance().enableFastUpload = true
					DJIVideoPreviewer.instance().encoderType = ._MavicAir
					DJIVideoPreviewer.instance().registFrameProcessor(self)
					DJIVideoPreviewer.instance().start()
					
					print("=== DjiPlugin iOS: Video feed started")
					self._fltSetStatus("Video Started")
					self._fltSetError("")
				}
			})
		} else {
			print("=== DjiPlugin iOS: Video record start failed - no Camera object")
			_fltSetStatus("Video Start Failed")
			_fltSetError("Video record start failed - no Camera object")
		}
	}
	
	public func videoFeedStopWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneCamera = drone?.camera {
			_droneCamera.setMode(DJICameraMode.recordVideo, withCompletion: { (error: Error?) in
				if (error != nil) {
					print("=== DjiPlugin iOS: Video feed stop failed with error - \(String(describing: error?.localizedDescription))")
					self._fltSetStatus("Video Stop Failed")
					self._fltSetError("Video feed stop failed with error - \(String(describing: error?.localizedDescription))")
				} else {
					DJISDKManager.videoFeeder()?.primaryVideoFeed.removeAllListeners()
					DJIVideoPreviewer.instance().close()
					DJIVideoPreviewer.instance().clearRender()
					DJIVideoPreviewer.instance().clearVideoData()
					DJIVideoPreviewer.instance().unregistFrameProcessor(self)
					
					self._fltSetStatus("Video Stopped")
					self._fltSetError("")
				}
			})
		} else {
			print("=== DjiPlugin iOS: Video feed stop failed - no Camera object")
			_fltSetStatus("Video Stop Failed")
			_fltSetError("Video feed stop failed - no Camera object")
		}
	}
	
	public func videoProcessorEnabled() -> Bool {
		return true
	}
	
	public func videoRecordStartWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneCamera = drone?.camera {
			_droneCamera.setMode(DJICameraMode.recordVideo, withCompletion: { (error: Error?) in
				if (error != nil) {
					print("=== DjiPlugin iOS: Video record start failed with error - \(String(describing: error?.localizedDescription))")
					self._fltSetStatus("Record Start Failed")
					self._fltSetError("Video record start failed with error - \(String(describing: error?.localizedDescription))")
				} else {
					_droneCamera.startRecordVideo() { (error: Error?) in
						if (error != nil) {
							print("=== DjiPlugin iOS: Video record start failed with error - \(String(describing: error?.localizedDescription))")
							self._fltSetStatus("Record Start Failed")
							self._fltSetError("Video record start failed with error - \(String(describing: error?.localizedDescription))")
						} else {
							print("=== DjiPlugin iOS: Video record started")
							self._fltSetStatus("Record Started")
							self._fltSetError("")
						}
					}
				}
			})
		} else {
			print("=== DjiPlugin iOS: Video record start failed - no Camera object")
			_fltSetStatus("Record Start Failed")
			_fltSetError("Video record start failed - no Camera object")
		}
	}
	
	public func videoRecordStopWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		if let _droneCamera = drone?.camera {
			_droneCamera.setMode(DJICameraMode.recordVideo, withCompletion: { (error: Error?) in
				if (error != nil) {
					print("=== DjiPlugin iOS: Video record stop failed with error - \(String(describing: error?.localizedDescription))")
					self._fltSetStatus("Record Stop Failed")
					self._fltSetError("Video record stop failed with error - \(String(describing: error?.localizedDescription))")
				} else {
					_droneCamera.stopRecordVideo() { (error: Error?) in
						if (error != nil) {
							print("=== DjiPlugin iOS: Video record stop failed with error - \(String(describing: error?.localizedDescription))")
							self._fltSetStatus("Record Stop Failed")
							self._fltSetError("Video record stop failed with error - \(String(describing: error?.localizedDescription))")
						} else {
							print("=== DjiPlugin iOS: Video record stopped")
							self._fltSetStatus("Record Stopped")
							self._fltSetError("")
						}
					}
				}
			})
		} else {
			print("=== DjiPlugin iOS: Video record stop failed - no Camera object")
			_fltSetStatus("Record Stop Failed")
			_fltSetError("Video record stop failed - no Camera object")
		}
	}
	
	// MARK: - Video Feed Delegate Methods
	
	public func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
		// Sending the data (H264 Raw byte-stream) to Flutter as Uint8List
		//_fltSendVideo(videoData)
		
		// Push video buffer into the DJI Video Previewer
		let videoNSData = videoData as NSData
		let videoBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: videoNSData.length)
		videoNSData.getBytes(videoBuffer, length: videoNSData.length)
		DJIVideoPreviewer.instance().push(videoBuffer, length: Int32(videoNSData.length))
	}
	
	public func videoProcessFrame(_ frame: UnsafeMutablePointer<VideoFrameYUV>!) {
//		if let buffer = frame.pointee.cv_pixelbuffer_fastupload {
//			let videoData = Data([UInt8](arrayLiteral: buffer.load(as: UInt8.self)))
//			_fltSendVideo(videoData)
//		}

		if frame.pointee.cv_pixelbuffer_fastupload != nil {
				//  cv_pixelbuffer_fastupload to CVPixelBuffer
				let cvBuf = unsafeBitCast(frame.pointee.cv_pixelbuffer_fastupload, to: CVPixelBuffer.self)
				let videoData = Data.from(pixelBuffer: cvBuf)

				//print("=== DjiPlugin iOS: videoProcessFrame - cv_pixelbuffer_fastupload - videoData: \(videoData)")
				_fltSendVideo(videoData)
		} else {
				// create CVPixelBuffer by your own, createPixelBuffer() is an extension function for VideoFrameYUV
				let pixelBuffer = createPixelBuffer(fromFrame: frame.pointee)
				guard let cvBuf = pixelBuffer else { return }
				let videoData = Data.from(pixelBuffer: cvBuf)

				//print("=== DjiPlugin iOS: videoProcessFrame - createPixelBuffer - videoData: \(videoData)")
				_fltSendVideo(videoData)
		}
	}
	
	func createPixelBuffer(fromFrame frame: VideoFrameYUV) -> CVPixelBuffer? {
		var initialPixelBuffer: CVPixelBuffer?
		let _: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault, Int(frame.width), Int(frame.height), kCVPixelFormatType_420YpCbCr8Planar, nil, &initialPixelBuffer)
		
		guard let pixelBuffer = initialPixelBuffer,
			CVPixelBufferLockBaseAddress(pixelBuffer, []) == kCVReturnSuccess
			else {
			return nil
		}
		
		let yPlaneWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
		let yPlaneHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
		
		let uPlaneWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1)
		let uPlaneHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
		
		let vPlaneWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 2)
		let vPlaneHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 2)
		
		let yDestination = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
		memcpy(yDestination, frame.luma, yPlaneWidth * yPlaneHeight)
		
		let uDestination = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1)
		memcpy(uDestination, frame.chromaB, uPlaneWidth * uPlaneHeight)
		
		let vDestination = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2)
		memcpy(vDestination, frame.chromaR, vPlaneWidth * vPlaneHeight)
		
		CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
		
		return pixelBuffer
	}

	// MARK: - DJISDKManager Delegate Methods

	public func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
		print("Downloading database: \(progress.completedUnitCount) / \(progress.totalUnitCount)")
	}

	public func appRegisteredWithError(_ error: Error?) {
		if error != nil {
			print("=== DjiPlugin iOS: Error: Register app failed! Please enter your app key and check the network.")
			_fltSetStatus("Error")
			_fltSetError("Register app failed! Please enter your app key and check the network.")
		} else {
			print("=== DjiPlugin iOS: Register App successful")
			_fltSetStatus("Registered")
			_fltSetError("")
		}
	}

	public func productConnected(_ product: DJIBaseProduct?) {
		// DJI Product is available only after registration and connection. So we initialize it here.
		if let _ = product {
			print("=== DjiPlugin iOS: Product Connected successfuly")
			_fltSetStatus("Connected")
			_fltSetError("")
		} else {
			print("=== DjiPlugin iOS: Error Connecting Product - DJIBaseProduct does not exist")
			_fltSetStatus("Error")
			_fltSetError("Error Connecting Product - DJIBaseProduct does not exist")
		}
	}

	public func productDisconnected() {
		print("=== DjiPlugin iOS: Product Disconnected")
		_fltSetStatus("Disconnected")
		_fltSetError("")
	}

	// MARK: - DJIBattery Delegate Methods

	public func battery(_: DJIBattery, didUpdate state: DJIBatteryState) {
		// Updating Flutter
		fltDrone.batteryPercent = Double(state.chargeRemainingInPercent) as NSNumber
		// print("=== DjiPlugin iOS: Battery Percent \(fltDrone.batteryPercent ?? 0)%")

		SwiftDjiPlugin.fltDjiFlutterApi?.setStatusDrone(fltDrone) { e in
			if let error = e {
				print("=== DjiPlugin iOS: Error: SetStatus Closure Error")
				NSLog("error: \(error.localizedDescription)")
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
				NSLog("error: \(error.localizedDescription)")
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

extension Data {
    public static func from(pixelBuffer: CVPixelBuffer) -> Self {
        CVPixelBufferLockBaseAddress(pixelBuffer, [.readOnly])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, [.readOnly]) }

        // Calculate sum of planes' size
        var totalSize = 0
        for plane in 0 ..< CVPixelBufferGetPlaneCount(pixelBuffer) {
            let height      = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
            let planeSize   = height * bytesPerRow
            totalSize += planeSize
        }

        guard let rawFrame = malloc(totalSize) else { fatalError() }
        var dest = rawFrame

        for plane in 0 ..< CVPixelBufferGetPlaneCount(pixelBuffer) {
            let source      = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, plane)
            let height      = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane)
            let planeSize   = height * bytesPerRow

            memcpy(dest, source, planeSize)
            dest += planeSize
        }

        return Data(bytesNoCopy: rawFrame, count: totalSize, deallocator: .free)
    }
}
