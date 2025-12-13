import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.coolsistema.becoolaguila"
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
        // Application ID for Google Play Store
        applicationId = "com.coolsistema.becoolaguila"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing if key.properties doesn't exist
                signingConfig = signingConfigs.getByName("debug")
            }
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

// AAB 파일 이름을 beCool.aab로 변경
afterEvaluate {
    // Bundle 작업에서 AAB 파일 이름 변경
    tasks.matching { it.name == "bundleRelease" }.configureEach {
        doLast {
            val bundleDir = file("${project.buildDir}/outputs/bundle/release")
            val originalAab = file("${bundleDir}/app-release.aab")
            val renamedAab = file("${bundleDir}/beCool.aab")
            
            if (originalAab.exists()) {
                originalAab.renameTo(renamedAab)
                println("✅ AAB 파일 이름 변경 완료: ${renamedAab.name}")
            }
        }
    }
    
    // APK 빌드 후 자동으로 Dropbox 폴더로 복사
    tasks.matching { it.name.startsWith("assemble") && it.name.endsWith("Release") }.configureEach {
        finalizedBy("copyApkToDropbox")
    }
}
