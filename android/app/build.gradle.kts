

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// --- ¡ESTAS SON LAS LÍNEAS IMPORTANTES QUE FALTABAN! ---
import java.util.Properties
import java.io.FileInputStream
// ----------------------------------------------------

// Carga las propiedades desde "android/key.properties"
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.compulsa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.adolfojuradorosas.compulsa"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Define la configuración de firma "release"
    signingConfigs {
        create("release") {
            storeFile = file("upload-key.jks")  // o file("upload-key.jks") si lo pones en android/app
            storePassword = "lavacalola"
            keyAlias = "upload"
            keyPassword = "lavacalola"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }

    }
}

flutter {
    source = "../.."
}