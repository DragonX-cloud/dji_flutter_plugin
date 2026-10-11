group = "cloud.dragonx.plugin.flutter.dji"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "cloud.dragonx.plugin.flutter.dji"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        // DJI MSDK v5 requires API 24.
        minSdk = 24
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // DJI MSDK v5: compile against the API jar, ship the runtime AAR (as in DJI's MSDK v5 sample).
    compileOnly("com.dji:dji-sdk-v5-aircraft-provided:5.18.0")
    implementation("com.dji:dji-sdk-v5-aircraft:5.18.0")
    // Generates the KMZ (WPML) files that MSDK v5 waypoint missions require; the version DJI's sample uses.
    implementation("com.dji:wpmzsdk:1.0.5.1")
    // Pigeon's Kotlin @async host methods are suspend functions.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
}
