plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Firebase Android Auth (reCAPTCHA) uchun "Web client" ID: google-services.jsonda bo‘lmasa ham shu string yetarli.
val firebaseSecretsFile = rootProject.file("firebase_secrets.properties")
val firebaseSecrets = Properties()
if (firebaseSecretsFile.exists()) {
    firebaseSecrets.load(FileInputStream(firebaseSecretsFile))
}
val localPropertiesFile = rootProject.file("local.properties")
val localProjectProps = Properties()
if (localPropertiesFile.exists()) {
    localProjectProps.load(FileInputStream(localPropertiesFile))
}
val defaultWebClientId: String? =
    firebaseSecrets.getProperty("defaultWebClientId")?.trim()?.takeIf { it.isNotEmpty() }
        ?: localProjectProps.getProperty("firebase.defaultWebClientId")?.trim()?.takeIf { it.isNotEmpty() }
        ?: System.getenv("FIREBASE_DEFAULT_WEB_CLIENT_ID")?.trim()?.takeIf { it.isNotEmpty() }

android {
    namespace = "com.example.geofield_pro_flutter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Firebase bilan mos kelishi uchun eskisiga qaytarildi
        applicationId = "com.example.geofield_pro_flutter"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        defaultWebClientId?.let { clientId ->
            resValue("string", "default_web_client_id", clientId)
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // reCAPTCHA / Google Sign-In bilan bog‘liq auth oqimlari
    implementation("com.google.android.gms:play-services-auth:21.2.0")
}
