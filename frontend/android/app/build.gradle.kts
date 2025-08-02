plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin must come after Android and Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.motoapp_frontend" // Paket adınız

    compileSdk = 35  // En az 35 olmalı, pluginlerin uyumu için

    ndkVersion = "27.0.12077973"  // Uygun NDK sürümü

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.motoapp_frontend"
        minSdk = flutter.minSdkVersion
        targetSdk = 35   // Burayı da 35 yap, uyumluluk için
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Prod ortamda uygun imzalama yapılmalı
        }
    }
}

dependencies {
    implementation("com.google.android.material:material:1.8.0")  // Material Components kütüphanesi
}

flutter {
    source = "../.."
}
