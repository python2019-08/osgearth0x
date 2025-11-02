#include <string.h>
#include <jni.h>
#include <android/log.h>

#include <iostream>

#include "OsgMainApp.hpp"

OsgMainApp mainApp;

extern "C" jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
    __android_log_write(ANDROID_LOG_ERROR, "OSGANDROID",
            "Entered JNI_OnLoad");
	return JNI_VERSION_1_6;
}

extern "C" {
    JNIEXPORT void JNICALL Java_com_oearth_androioearth01_osgNativeLib_init(JNIEnv * env, jobject obj, 
        jint width, jint height);
    JNIEXPORT void JNICALL Java_com_oearth_androioearth01_osgNativeLib_step(JNIEnv * env, jobject obj);
    JNIEXPORT void JNICALL Java_com_oearth_androioearth01_osgNativeLib_touchBeganEvent(JNIEnv * env, jobject obj, 
        jint touchid, jfloat x, jfloat y);
    JNIEXPORT void JNICALL Java_com_oearth_androioearth01_osgNativeLib_touchMovedEvent(JNIEnv * env, jobject obj, 
        jint touchid, jfloat x, jfloat y);
    JNIEXPORT void JNICALL Java_com_oearth_androioearth01_osgNativeLib_touchZoomEvent(JNIEnv * env, jobject obj, 
        jdouble delta);

    JNIEXPORT void JNICALL
    Java_com_oearth_androioearth01_osgNativeLib_touchRotationEvent(JNIEnv * env, jobject obj,
                                                                    jdouble aDelta);
    JNIEXPORT void JNICALL Java_com_oearth_androioearth01_osgNativeLib_touchEndedEvent(JNIEnv * env, jobject obj, 
        jint touchid, jfloat x, jfloat y, jint tapcount);
    JNIEXPORT void JNICALL Java_com_oearth_androioearth01_osgNativeLib_clearEventQueue(JNIEnv * env, jobject obj);
    JNIEXPORT void JNICALL Java_com_oearth_androioearth01_osgNativeLib_setDataFilePath(JNIEnv * env, jobject obj, 
        jstring dataPath, jstring packagePath, jobject assetManager);
 

    //-----------------------
    JNIEXPORT void JNICALL
    Java_com_oearth_androioearth01_osgNativeLib_mouseButtonPressEvent(JNIEnv * env, jobject obj,
                     jfloat x, jfloat y, jint button);
    JNIEXPORT void JNICALL
    Java_com_oearth_androioearth01_osgNativeLib_mouseButtonReleaseEvent(JNIEnv * env, jobject obj,
                     jfloat x, jfloat y, jint button);

    JNIEXPORT void JNICALL 
    Java_com_oearth_androioearth01_osgNativeLib_mouseMoveEvent(JNIEnv * env, jobject obj,
                                jfloat x, jfloat y);                          
};

JNIEXPORT void JNICALL 
Java_com_oearth_androioearth01_osgNativeLib_init(JNIEnv * env, jobject obj, jint width, jint height)
{
    mainApp.initOsgWindow(0,0,width,height);
}
JNIEXPORT void JNICALL 
Java_com_oearth_androioearth01_osgNativeLib_step(JNIEnv * env, jobject obj)
{
    mainApp.draw();
}

// -----------------------------
// touch events
JNIEXPORT void JNICALL 
Java_com_oearth_androioearth01_osgNativeLib_touchBeganEvent(JNIEnv * env, jobject obj,
                            jint touchid, jfloat x, jfloat y)
{
    mainApp.touchBeganEvent(touchid,x,y);
}
JNIEXPORT void JNICALL 
Java_com_oearth_androioearth01_osgNativeLib_touchMovedEvent(JNIEnv * env, jobject obj,
                            jint touchid, jfloat x, jfloat y)
{
    mainApp.touchMovedEvent(touchid,x,y);
}

JNIEXPORT void JNICALL 
Java_com_oearth_androioearth01_osgNativeLib_touchZoomEvent(JNIEnv * env, jobject obj,
                                                           jdouble delta)
{
    mainApp.touchZoomEvent(delta);
}


JNIEXPORT void JNICALL
Java_com_oearth_androioearth01_osgNativeLib_touchRotationEvent(JNIEnv * env, jobject obj,
                                                               jdouble aDelta)
{
    mainApp.touchRotationEvent(aDelta);
}

JNIEXPORT void JNICALL 
Java_com_oearth_androioearth01_osgNativeLib_touchEndedEvent(JNIEnv * env, jobject obj, 
    jint touchid, jfloat x, jfloat y, jint tapcount)
{
    mainApp.touchEndedEvent(touchid,x,y,tapcount);
}

// -----------------------------
JNIEXPORT void JNICALL 
Java_com_oearth_androioearth01_osgNativeLib_clearEventQueue(JNIEnv * env, jobject obj)
{
    mainApp.clearEventQueue();
}

// -----------------------------
JNIEXPORT void JNICALL  
Java_com_oearth_androioearth01_osgNativeLib_setDataFilePath(JNIEnv * env, jobject obj, 
                    jstring dataPath, 
                    jstring packagePath, 
                    jobject assetManager)
{
    //Import Strings from JNI
    const char *nativeDataPath = env->GetStringUTFChars(dataPath, JNI_FALSE);
    const char *nativePackagePath = env->GetStringUTFChars(packagePath, JNI_FALSE);

    mainApp.setDataPath(std::string(nativeDataPath), std::string(nativePackagePath));

    //Release Strings to JNI
    env->ReleaseStringUTFChars(packagePath, nativePackagePath);
    env->ReleaseStringUTFChars(dataPath, nativeDataPath);
}

// -----------------------------
// mouseButton Events
JNIEXPORT void JNICALL 
Java_com_oearth_androioearth01_osgNativeLib_mouseButtonPressEvent(JNIEnv * env, jobject obj,
                                   jfloat x, jfloat y, jint button)
{
    mainApp.mouseButtonPressEvent(x,y,button);
}

JNIEXPORT void JNICALL 
Java_com_oearth_androioearth01_osgNativeLib_mouseButtonReleaseEvent(JNIEnv * env, jobject obj,
                                    jfloat x, jfloat y, jint button)
{
    mainApp.mouseButtonReleaseEvent(x,y,button);
}

JNIEXPORT void JNICALL 
Java_com_oearth_androioearth01_osgNativeLib_mouseMoveEvent(JNIEnv * env, jobject obj,
                            jfloat x, jfloat y)
{
    mainApp.mouseMoveEvent(x,y);
}
