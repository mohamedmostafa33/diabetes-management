plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_"
    compileSdk = 35 // تغيير إلى 35 (Android 15) حسب طلب الـ plugins
    ndkVersion = "27.0.12077973" // تغيير إلى الإصدار المطلوب من الـ plugins

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.flutter_"
        minSdk = 28 // Android 9
        targetSdk = 35 // تغيير إلى 35 ليتوافق مع compileSdk
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true // دعم MultiDex للإصدارات القديمة
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1") // دعم MultiDex
}