plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")

    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by `flutter_local_notifications` 21.x — backports Java 8+
        // APIs (e.g. java.time) to older Android API levels. Without this,
        // `:app:checkDebugAarMetadata` fails with "core library desugaring
        // must be enabled."
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.frontend"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Booking orchestrator session 4 — Google Maps API key plumbing.
        // The manifest's `<meta-data android:name="com.google.android.geo.API_KEY">`
        // reads ${GOOGLE_MAPS_API_KEY}; this resolves it from the build env.
        // Empty string is acceptable — the OSM provider is the dev default
        // and Google Maps will simply render blank tiles when the key is
        // empty (flag #16 footgun, deliberately surfaced visually).
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] =
            System.getenv("GOOGLE_MAPS_API_KEY") ?: ""
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Companion to `compileOptions.isCoreLibraryDesugaringEnabled = true`.
// The plugin requires this artifact on the `coreLibraryDesugaring`
// classpath. Version pinned to a known-good release for AGP 8.x.
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
