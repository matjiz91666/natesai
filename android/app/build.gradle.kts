plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
android {
    namespace = "com.natesfinefoods.productionpro"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    defaultConfig {
        applicationId = "com.natesfinefoods.productionpro"
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }
    buildTypes { release { signingConfig = signingConfigs.getByName("debug") } }
}
flutter { source = "../.." }
