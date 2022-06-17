package cloud.dragonx.plugin.flutter.djiExample;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;

import io.flutter.Log;
import io.flutter.embedding.engine.FlutterEngine;

@Keep
public final class CustomPluginRegistrant {
  private static final String TAG = "CustomPluginRegistrant";
  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
    try {
      flutterEngine.getPlugins().add(new com.arthenica.ffmpegkit.flutter.FFmpegKitFlutterPlugin());
    } catch(Exception e) {
      Log.e(TAG, "Error registering plugin ffmpeg_kit_flutter, com.arthenica.ffmpegkit.flutter.FFmpegKitFlutterPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.rmawatson.flutterisolate.FlutterIsolatePlugin());
    } catch(Exception e) {
      Log.e(TAG, "Error registering plugin flutter_isolate, com.rmawatson.flutterisolate.FlutterIsolatePlugin", e);
    }
  }
}
