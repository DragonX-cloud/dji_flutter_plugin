pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// R8 9.1.31, bundled with AGP 9.1.x, crashes (NullPointerException in its Android API modeling) on
// release builds that include DJI MSDK v5, whose consumer rules keep all of androidx. R8 9.1.56 fixes it.
buildscript {
    repositories {
        google()
    }
    dependencies {
        classpath("com.android.tools:r8:9.1.56")
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
