#include <string.h>
#include <jni.h>
#include <android/log.h>

#include <iostream>

#include "OsgMainApp.hpp"

OsgMainApp mainApp;

extern "C" {
    JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_init(JNIEnv * env, jobject obj, jint width, jint height);
    JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_step(JNIEnv * env, jobject obj);
    JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_mouseButtonPressEvent(JNIEnv * env, jobject obj, jfloat x, jfloat y, jint button);
    JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_mouseButtonReleaseEvent(JNIEnv * env, jobject obj, jfloat x, jfloat y, jint button);
    JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_mouseMoveEvent(JNIEnv * env, jobject obj, jfloat x, jfloat y);
    JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_keyboardDown(JNIEnv * env, jobject obj, jint key);
    JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_keyboardUp(JNIEnv * env, jobject obj, jint key);
};

extern "C" JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_init(JNIEnv * env, jobject obj, jint width, jint height){
    mainApp.initOsgWindow(0,0,width,height);
}

extern "C" JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_step(JNIEnv * env, jobject obj){
    mainApp.draw();
}

extern "C" JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_mouseButtonPressEvent(JNIEnv * env, jobject obj, jfloat x, jfloat y, jint button){
    mainApp.mouseButtonPressEvent(x,y,button);
}

extern "C" JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_mouseButtonReleaseEvent(JNIEnv * env, jobject obj, jfloat x, jfloat y, jint button){
    mainApp.mouseButtonReleaseEvent(x,y,button);
}

extern "C" JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_mouseMoveEvent(JNIEnv * env, jobject obj, jfloat x, jfloat y){
    mainApp.mouseMoveEvent(x,y);
}
extern "C" JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_keyboardDown(JNIEnv * env, jobject obj, jint key){
    mainApp.keyboardDown(key);
}
extern "C" JNIEXPORT void JNICALL Java_osg_AndroidExample_osgNativeLib_keyboardUp(JNIEnv * env, jobject obj, jint key){
    mainApp.keyboardUp(key);
}

