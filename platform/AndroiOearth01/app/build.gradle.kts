plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "com.oearth.androioearth01"
    compileSdk {
        version = release(36)
    }

    defaultConfig {
        applicationId = "com.oearth.androioearth01"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        externalNativeBuild {
            cmake {
                cppFlags += "-std=c++17"
                val libPath = project.file("../../../build_by_sh/install/android/3rd/").absolutePath // 动态获取路径
                arguments += listOf(
                    "-DInstallRoot_3rd=$libPath",      // 动态传递路径
                    "-DANDROID_STL=c++_shared", // 其他CMake参数
                    "-DANDROID_PAGE_SIZE_ALIGNMENT=16384",
                    "-DCMAKE_BUILD_TYPE=Debug",
                    "-DANDROID=1"
                )
            }
        }

        ndk {
            // 指定要构建的 ABI（默认情况下，Gradle 会构建所有支持的 ABI）"armeabi-v7a", "x86", 
            // abiFilters += listOf("arm64-v8a", "x86_64")
            abiFilters += listOf("arm64-v8a" ,"x86_64")
        }        
    }

    buildTypes {
        getByName("release") {
            isDebuggable = true
            isJniDebuggable = true
            isRenderscriptDebuggable = true
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            isMinifyEnabled = false  // 关闭混淆
            isDebuggable= true
            isJniDebuggable=true    // 启用 NDK 调试
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    externalNativeBuild {
        cmake {
            path = file("src/main/jni/CMakeLists.txt")
            version = "3.22.1"
        }
    }
    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    implementation(libs.appcompat)
    implementation(libs.material)
    implementation(libs.constraintlayout)
    testImplementation(libs.junit)
    androidTestImplementation(libs.ext.junit)
    androidTestImplementation(libs.espresso.core)
}