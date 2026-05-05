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

// default_web_client_id string resursi: com.google.gms.google-services plarugini
// google-services.json (OAuth) dan bitta marta hosil qiladi. Qo'lda resValue qo'shish
// mergeDebugResourcesda "Duplicate resources" (dublikat) beradi.

android {
    namespace = "com.aurum.geofieldpro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        // Play Store va google-services.json dagi package_name bilan bir xil bo‘lishi kerak
        applicationId = "com.aurum.geofieldpro"

        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
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

// Play/reliz: key.properties bo‘lmasa release APK/AAB grafigi ishlamasin.
gradle.taskGraph.whenReady {
    fun isReleaseApkOrBundleTask(name: String): Boolean {
        if (name == "assembleRelease" || name == "bundleRelease" || name == "packageRelease") return true
        if (name.startsWith("assemble") && name.endsWith("Release")) return true
        if (name.startsWith("bundle") && name.endsWith("Release")) return true
        if (name.startsWith("package") && name.endsWith("Release")) return true
        return false
    }
    val wantsRelease = allTasks.any { isReleaseApkOrBundleTask(it.name) }
    if (wantsRelease && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "Release yig‘ish uchun android/key.properties kerak (Play uchun debug imzo taqiqlanadi). " +
                "Qo‘llanma: geofield_pro_flutter/docs/ANDROID_RELEASE.md",
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase Android (BOM) — Flutter Firebase loyha bog‘liqliklari pubspec orqali
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // reCAPTCHA / Google Sign-In bilan bog‘liq auth oqimlari
    implementation("com.google.android.gms:play-services-auth:21.2.0")
}
