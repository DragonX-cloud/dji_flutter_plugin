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

public class SwiftDjiPlugin: FLTDjiFlutterApi, FlutterPlugin, FLTDjiHostApi, DJISDKManagerDelegate {
	
	static var fltDjiFlutterApi : FLTDjiFlutterApi?
	
	public static func register(with registrar: FlutterPluginRegistrar) {
		let messenger : FlutterBinaryMessenger = registrar.messenger()
		let api : FLTDjiHostApi = SwiftDjiPlugin.init()
		FLTDjiHostApiSetup(messenger, api)
		fltDjiFlutterApi = FLTDjiFlutterApi.init(binaryMessenger: messenger)
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

	public func registerDjiApp(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
		print("=== registerDjiApp Started")
		DJISDKManager.registerApp(with: self)		
	}
	
	//MARK: - DJISDKManagerDelegate Methods
    
	public func productConnected(_ product: DJIBaseProduct?) {
		print("=== Product Connected")
	}

	public func productDisconnected() {
		print("=== Product Disconnected")
	}

	public func appRegisteredWithError(_ error: Error?) {
		if (error != nil) {
			print("=== Error: Register app failed! Please enter your app key and check the network.")
		} else {
			DJISDKManager.startConnectionToProduct()
			print("=== Register App Successed!")
			
			let fltDrone = FLTDrone()
			fltDrone.droneStatus = "Connected"
			
			SwiftDjiPlugin.fltDjiFlutterApi?.setDroneStatus(fltDrone) {e in
				if let error = e {
					print("=== Error: SetDroneStatus Closure Error")
					NSLog("error: %@", error.localizedDescription)
				} else {
					print("=== setDroneStatus Closure Success")
				}
			}
		}
	}

	public func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
		print("Downloading database: \(progress.completedUnitCount) / \(progress.totalUnitCount)")
	}

}

