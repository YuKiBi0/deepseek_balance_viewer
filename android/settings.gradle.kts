pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val path = properties.getProperty("flutter.sdk")
        require(path != null) { "flutter.sdk not set in local.properties" }
        path
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
}

// Read Flutter SDK path, engine version, and realm
val flutterSdkPath: String by lazy {
    val properties = java.util.Properties()
    file("local.properties").inputStream().use { properties.load(it) }
    val path = properties.getProperty("flutter.sdk")
    require(path != null) { "flutter.sdk not set in local.properties" }
    path
}

val engineRealm: String by lazy {
    var realm = java.io.File(flutterSdkPath, "bin/cache/engine.realm").readText().trim()
    if (realm.isNotEmpty()) "$realm/" else ""
}

val flutterStorageUrl: String by lazy {
    System.getenv("FLUTTER_STORAGE_BASE_URL") ?: "https://storage.googleapis.com"
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("$flutterStorageUrl/${engineRealm}download.flutter.io")
        }
    }
}

rootProject.name = "deepseek_balance_viewer"
include(":app")
