package cloud.dragonx.plugin.flutter.dji

import android.app.Application
import android.content.Context

/**
 * DJI MSDK v5 must be installed in [Application.attachBaseContext], before any DJI class is loaded.
 * A Flutter plugin cannot hook into the host app's Application, so the host app declares this class
 * (or a subclass) as `android:name` of its `<application>` element.
 */
open class DjiApplication : Application() {
  override fun attachBaseContext(base: Context?) {
    super.attachBaseContext(base)
    com.cySdkyc.clx.Helper.install(this)
  }
}
