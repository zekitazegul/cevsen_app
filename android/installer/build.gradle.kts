plugins {
    id("com.android.application")
}

android {
    namespace = "com.zek.cevsen_installer"
    compileSdk = 36
    defaultConfig {
        applicationId = "com.zek.cevsen_installer"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        buildConfigField("String", "MANIFEST_URL", "\"https://github.com/zekitazegul/cevsen_app/releases/latest/download/update.json\"")
    }
    buildFeatures { buildConfig = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildTypes {
        debug {
            val testUrl = providers.gradleProperty("installerTestManifestUrl").orNull
            if (testUrl != null) {
                require(testUrl.matches(Regex("http://127\\.0\\.0\\.1:[0-9]+/update\\.json")))
                buildConfigField("String", "MANIFEST_URL", "\"$testUrl\"")
            }
        }
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }
}
