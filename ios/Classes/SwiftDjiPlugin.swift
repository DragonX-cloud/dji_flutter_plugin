import Foundation
import DJISDK
import DJIWidget
import Flutter
import UIKit
import ffmpegkit

public class SwiftDjiPlugin: FLTDjiFlutterApi, FlutterPlugin, FLTDjiHostApi, DJISDKManagerDelegate, DJIFlightControllerDelegate, DJIBatteryDelegate, DJIVideoFeedListener {
	
	static var fltDjiFlutterApi: FLTDjiFlutterApi?
	let fltDrone = FLTDrone()
	let fltStream = FLTStream()
	
	var drone: DJIAircraft?
	var droneCurrentLocation: CLLocation?
	var mediaFileList = [DJIMediaFile?]()
	var videoFeedInputPath: String?
	var videoFeedOutputPath: String?
	var videoFeedOutputFile: File?
	
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
			print("=== DjiPlugin iOS: startFlightTimeline - timeline List is empty")
			return
		}

		guard let _droneFlightController = drone?.flightController else {
			print("=== DjiPlugin iOS: startFlightTimeline - No Flight Controller")
			return
		}
		
		if (DJISDKManager.missionControl()?.isTimelineRunning == true) {
			print("=== DjiPlugin iOS: startFlightTimeline - Timeline already running - attempting to stop it")
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
				}
			})
			
			// Adding the scheduled elements
			var timelineSchedulingCompleted: Bool = true
			for element in scheduledElements {
				let error = _missionControl.scheduleElement(element)
				if error != nil {
					NSLog("=== DjiPlugin iOS: Timeline Failed - Error scheduling element \(String(describing: error))")
					timelineSchedulingCompleted = false
					return
				}
			}
			if timelineSchedulingCompleted {
				// Starting Motors
				// _droneFlightController.turnOnMotors(completion: nil)

				// Starting the Timeline Mission
				_missionControl.startTimeline()
			}
		} else {
			NSLog("=== DjiPlugin iOS: startFlightTimeline - No Mission Control or Scheduled Elements")
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
				} else {
					print("=== DjiPlugin iOS: Get media list started")
					
					if let _droneMediaManager = _droneCamera.mediaManager {
						// Fetching the Media List from the Drone's SD Card
						if _droneMediaManager.sdCardFileListState == DJIMediaFileListState.syncing ||
						   _droneMediaManager.sdCardFileListState == DJIMediaFileListState.deleting {
							print("=== DjiPlugin iOS: Get media list failed - Media Manager is busy")
							self._fltSetStatus("Media List Failed")
						} else {
							_droneMediaManager.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: {[weak self] (e: Error?) in
								if let error = e {
									print("=== DjiPlugin iOS: Get media list failed: \(error.localizedDescription)")
									self?._fltSetStatus("Media List Failed")
								} else {
									if let sdCardMediaFileList = _droneMediaManager.sdCardFileListSnapshot() {
										print("=== DjiPlugin iOS: Get media list successful")
										self?._fltSetStatus("Got Media List")
										
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
									}
								}
							})
						}
					} else {
						print("=== DjiPlugin iOS: Get media list - no Media Manager")
						self._fltSetStatus("Media List Failed")
					}
				}
			})
		} else {
			print("=== DjiPlugin iOS: Get media list - no Camera object")
			_fltSetStatus("Media List Failed")
		}
		
		return _fltMediaList
	}
	
	public func downloadMediaFileIndex(_ fileIndex: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> String? {
		var _mediaURLString: String = ""
		let _index: Int = fileIndex.intValue

		guard _index >= 0 else {
			print("=== DjiPlugin iOS: Download media failed - invalid index")
			_fltSetStatus("Download Failed")

			return ""
		}

		guard !mediaFileList.isEmpty else {
			print("=== DjiPlugin iOS: Download media failed - list is empty")
			_fltSetStatus("Download Failed")

			return ""
		}

		if let _droneCamera = drone?.camera {
			_droneCamera.setMode(DJICameraMode.mediaDownload, withCompletion: { (error: Error?) in
				if (error != nil) {
					print("=== DjiPlugin iOS: Download media - set camera mode failed with error - \(String(describing: error?.localizedDescription))")
					self._fltSetStatus("Download Failed")
				} else {
					print("=== DjiPlugin iOS: Download media started")
					self._fltSetStatus("Download Started")

					if let selectedMedia = self.mediaFileList[_index] {
						let isPhoto = selectedMedia.mediaType == DJIMediaType.JPEG || selectedMedia.mediaType == DJIMediaType.TIFF
						var previousOffset = UInt(0)
						var fileData: Data?

						selectedMedia.fetchData(withOffset: previousOffset, update: DispatchQueue.main, update: {[weak self] (data:Data?, isComplete: Bool, e: Error?) in
							if let error = e {
								print("=== DjiPlugin iOS: Download media failed - Fetch File Data: \(error.localizedDescription)")
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

									print("=== DjiPlugin iOS: Download media completed: \(mediaURL.absoluteString)")
									self?._fltSetStatus("Downloaded")

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

										} else if let error = e {
											print("=== DjiPlugin iOS: Failed to save media to gallery - \(error.localizedDescription)")
											self?._fltSetStatus("Download Failed")
										}
									}
								}
							}
						})
					} else {
						print("=== DjiPlugin iOS: Download media - file not found")
						self._fltSetStatus("Download Failed")
					}
				}
			})
		} else {
			print("=== DjiPlugin iOS: Download all media failed - no Camera object")
			_fltSetStatus("Download Failed")
		}

		return _mediaURLString
	}
	
	public func deleteMediaFileIndex(_ fileIndex: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
		var _success: Bool = false
		let _index: Int = fileIndex.intValue
		
		guard _index >= 0 else {
			print("=== DjiPlugin iOS: Delete media failed - invalid index")
			_fltSetStatus("Delete Failed")
			
			return nil
		}
		
		guard !mediaFileList.isEmpty else {
			print("=== DjiPlugin iOS: Delete media failed - list is empty")
			_fltSetStatus("Delete Failed")
			
			return nil
		}
		
		if let _droneCamera = drone?.camera {
			_droneCamera.setMode(DJICameraMode.mediaDownload, withCompletion: { (error: Error?) in
				if (error != nil) {
					print("=== DjiPlugin iOS: Delete media failed with error - \(String(describing: error?.localizedDescription))")
					self._fltSetStatus("Delete Failed")
				} else {
					print("=== DjiPlugin iOS: Delete media started")
					self._fltSetStatus("Delete Started")
					
					if let _droneMediaManager = _droneCamera.mediaManager {
						if let selectedMedia = self.mediaFileList[_index] {
							_droneMediaManager.delete([selectedMedia])
							
							print("=== DjiPlugin iOS: Delete media completed")
							self._fltSetStatus("Deleted")
							_success = true
						} else {
							print("=== DjiPlugin iOS: Delete media - file not found")
							self._fltSetStatus("Download Failed")
							_success = false
						}
					} else {
						print("=== DjiPlugin iOS: Delete media failed - no Playback Manager")
						
						self._fltSetStatus("Delete Failed")
						_success = false
					}
				}
			})
		} else {
			print("=== DjiPlugin iOS: Delete all media failed - no Camera object")
			_fltSetStatus("Delete Failed")
			_success = false
		}
		
		return _success as NSNumber
	}
	
	// MARK: - Video Feed Methods
	
	public func videoFeedStartWithError(_ outputPath, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		videoFeedOutputPath = outputPath
		videoFeedOutputFile = FileHandle(forWritingAtPath: outputPath)
		
		if let inputPipe = FFmpegKitConfig.registerNewFFmpegPipe(), let outputPipe = videoFeedOutputFile {
			videoFeedInputPath = inputPipe
			
			// Converting the input video data pipe into an MP4 file
			FFmpegKit.executeAsync("-y -avioflags direct -max_delay 0 -flags2 showall -f h264 -i \(inputPipe) -fflags nobuffer+discardcorrupt+noparse+nofillin+ignidx+flush_packets+fastseek -avioflags direct -max_delay 0 -f mp4 -movflags frag_keyframe+empty_moov \(outputPipe)") { ffmpegSession in
				// print(ffmpegSession?.getStatistics());
			}
			// Starting the DJI Video Feed
			DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
		}
	}
	
	public func videoFeedStopWithError(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		DJISDKManager.videoFeeder()?.primaryVideoFeed.removeAllListeners()
	}
	
	// MARK: - Video Feed Delegate Methods
	
	public func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
		// Sending the data (H264 Raw byte-stream) to Flutter as Uint8List
		_fltSendVideo(videoData)

		// Converting to MP4 using FFMPEG and saving to file
		if () {
			inputFile.write(videoData)
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
			print("=== DjiPlugin iOS: Register App successful")
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
