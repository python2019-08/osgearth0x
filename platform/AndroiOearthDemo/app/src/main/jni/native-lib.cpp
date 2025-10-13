#include <jni.h>
#include <string>

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_androioearthdemo_MainActivity_stringFromJNI(
        JNIEnv* env,
        jobject /* this */)
{
    std::string hello = "Hello from C++444455556666";
    return env->NewStringUTF(hello.c_str());
}