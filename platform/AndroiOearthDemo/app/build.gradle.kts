plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "com.example.androioearthdemo"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.androioearthdemo"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        externalNativeBuild {
            cmake {
                cppFlags += "-std=c++17"
                val libPath = project.file("../../../build_by_sh/android/install/3rd/").absolutePath // 动态获取路径
                arguments += listOf(
                    "-DLibs3rd_RootDIR=$libPath",      // 动态传递路径
                    "-DANDROID_STL=c++_shared" // 其他CMake参数
 
                )
            }
        }

        ndk {
            // 指定要构建的 ABI（默认情况下，Gradle 会构建所有支持的 ABI）"armeabi-v7a", "x86", 
            // abiFilters += listOf("arm64-v8a", "x86_64")
            abiFilters += listOf("x86_64")
        }        
    }

    buildTypes {
        release {
            isMinifyEnabled = false
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