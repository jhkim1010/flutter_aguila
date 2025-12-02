plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.flutter_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
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

flutter {
    source = "../.."
}

// APK 빌드 후 자동으로 Dropbox 폴더로 복사 (Be_Cool.apk로 이름 변경)
tasks.register("copyApkToDropbox") {
    doLast {
        // Flutter는 app-release.apk로 빌드하므로 원본 파일명 사용
        val apkFile = file("${project.buildDir}/outputs/flutter-apk/app-release.apk")
        val dropboxDir = file("/Users/marcoskim/Dropbox/ACE_3_uversion")
        
        if (apkFile.exists()) {
            dropboxDir.mkdirs()
            // Be_Cool.apk로 이름 변경하여 복사
            val targetFile = file("${dropboxDir}/Be_Cool.apk")
            apkFile.copyTo(targetFile, overwrite = true)
            println("✅ APK 파일이 Dropbox로 복사되었습니다: ${targetFile.absolutePath}")
        } else {
            println("⚠️ APK 파일을 찾을 수 없습니다: ${apkFile.absolutePath}")
        }
    }
}

// 모든 빌드 타입의 assemble 작업 후 복사
afterEvaluate {
    tasks.matching { it.name.startsWith("assemble") && it.name.endsWith("Release") }.configureEach {
        finalizedBy("copyApkToDropbox")
    }
}
