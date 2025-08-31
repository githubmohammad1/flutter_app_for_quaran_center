// ✅ استيراد المكتبات اللازمة للتاريخ
import java.text.SimpleDateFormat
import java.util.Date

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.quran_progress_app2"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.quran_progress_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // 📌 إعادة تسمية ملف الـ APK الناتج تلقائيًا
    applicationVariants.all {
        outputs.all {
            val appName = "QuranProgressApp" // ← غيّر هذا لاسمك المخصص
            val buildTypeName = buildType.name
            val versionNameValue = versionName
            val buildDate = SimpleDateFormat("yyyy-MM-dd").format(Date())

            // إعادة التسمية
            (this as com.android.build.gradle.internal.api.BaseVariantOutputImpl).outputFileName =
                "${appName}-v${versionNameValue}-${buildDate}-${buildTypeName}.apk"
        }
    }
}

flutter {
    source = "../.."
}
