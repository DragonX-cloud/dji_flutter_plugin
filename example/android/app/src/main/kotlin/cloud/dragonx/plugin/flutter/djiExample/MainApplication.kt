package cloud.dragonx.plugin.flutter.djiExample

import com.rmawatson.flutterisolate.FlutterIsolatePlugin
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication() {
    init {
        FlutterIsolatePlugin.setCustomIsolateRegistrant(CustomPluginRegistrant::class.java);
    }
}