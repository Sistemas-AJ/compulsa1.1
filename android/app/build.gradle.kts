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
        applicationId = "com.example.compulsa"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Define la configuración de firma "release"
    signingConfigs {
        create("release") {
            // Obtenemos todas las propiedades primero
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            val storePass = keystoreProperties.getProperty("storePassword")
            val keyAliasVal = keystoreProperties.getProperty("keyAlias")
            val keyPass = keystoreProperties.getProperty("keyPassword")

            // Verificamos que NINGUNA sea nula
            if (storeFilePath != null && storePass != null && keyAliasVal != null && keyPass != null) {

                // --- ¡ESTA ES LA CORRECCIÓN! ---
                // Usamos file() en lugar de rootProject.file()
                // file() SÍ sabe manejar rutas absolutas.
                storeFile = file(storeFilePath) 
                // ---------------------------------

                storePassword = storePass
                keyAlias = keyAliasVal
                keyPassword = keyPass
            } else {
                // Si falta algo, fallamos con un error claro.
                throw GradleException("Faltan propiedades de firma en android/key.properties. " +
                    "Asegúrate de que storeFile, storePassword, keyAlias, y keyPassword estén definidos.")
            }
        }
    }

    buildTypes {
        release {
            // Le decimos a Gradle que use nuestra firma "release"
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}