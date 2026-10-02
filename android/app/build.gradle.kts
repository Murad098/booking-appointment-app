// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    // FlutterFire — must come AFTER com.android.application
    id("com.google.gms.google-services")
    id("kotlin-android")
    // Flutter plugin must be last
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bookify"
    compileSdk = 36          // ← pin to 35 instead of flutter.compileSdkVersion
    //   so FCM / Firebase libs always find the right SDK
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true   // needed for flutter_local_notifications
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.bookify"

        // FCM requires minSdk 21 (Android 5.0+).
        // flutter.minSdkVersion is usually 16 — override it here.
        minSdk = flutter.minSdkVersion

        targetSdk = 36       // target Android 14 so POST_NOTIFICATIONS works correctly
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Keeps multidex available if your method count grows
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Use your real signing config for release APKs.
            // Leaving debug keys here is fine for testing but NOT for Play Store.
            signingConfig = signingConfigs.getByName("debug")

            // Disable shrinking/obfuscation for now so FCM service classes
            // are not accidentally removed by R8. Enable + add keep rules
            // once you're ready for production.
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            isDebuggable = true
        }
    }
}

dependencies {
    // Core library desugaring — required by flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Firebase BOM — controls ALL Firebase/FCM library versions together.
    // Always use the BOM so versions don't conflict.
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))

    // FCM — version comes from the BOM, do NOT add a version number here
    implementation("com.google.firebase:firebase-messaging")

    // If you use Firebase Analytics (FlutterFire default), keep this too
    implementation("com.google.firebase:firebase-analytics")

    // Multidex support for minSdk < 21 (kept for safety)
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
