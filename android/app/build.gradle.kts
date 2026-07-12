import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val localProperties = Properties()

val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val keystoreProperties = Properties()

val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.reader(Charsets.UTF_8).use { reader ->
        keystoreProperties.load(reader)
    }
}

val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

/** Expands a leading `~` (Gradle's file() does not). */
fun expandHome(path: String): String =
    if (path.startsWith("~")) System.getProperty("user.home") + path.substring(1) else path


val myCompileSdk: Int = localProperties.getProperty("local.compileSdk")?.toInt() ?: flutter.compileSdkVersion
val myNdkVersion: String = localProperties.getProperty("local.ndkVersion") ?: flutter.ndkVersion
val myMinSdk: Int = localProperties.getProperty("local.minSdk")?.toInt() ?: flutter.minSdkVersion
val myTargetSdk: Int = localProperties.getProperty("local.targetSdk")?.toInt() ?: flutter.targetSdkVersion

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
        targetSdk = myTargetSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(expandHome(keystoreProperties.getProperty("storeFile")))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Falls back to debug signing when key.properties is absent,
            // so `flutter run --release` still works on machines without the keystore.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
