plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
import java.util.Properties

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val myCompileSdk: Int = localProperties.getProperty("local.compileSdk")?.toInt() ?: flutter.compileSdkVersion
val myNdkVersion: String = localProperties.getProperty("local.ndkVersion") ?: flutter.ndkVersion
val myMinSdk: Int = localProperties.getProperty("local.minSdk")?.toInt() ?: flutter.minSdkVersion

android {
    namespace = "id.muhamadanjar.app"
    compileSdk = myCompileSdk
    //ndkVersion = flutter.ndkVersion
    ndkVersion = myNdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "id.muhamadanjar.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = myMinSdk
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
  implementation(platform("com.google.firebase:firebase-bom:34.15.0"))

  implementation("com.google.firebase:firebase-analytics")
}


flutter {
    source = "../.."
}
