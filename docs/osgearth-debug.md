# 1. compileShader(osg::State& state)

/home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Shader.cpp:582:  Shader::PerContextShader::compileShader(osg::State& state)

/home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/src/osg/Drawable.cpp557: virtual void drawElements(GLenum,GLsizei count,const GLushort* indices) 
/home/abner/abner2/zdev/nv/osgearth0x/3rd/osg/include/osg/TemplatePrimitiveIndexFunctor:246:  virtual void drawElements(GLenum mode,GLsizei count,const GLushort* indices)

#if defined(OSG_GLES1_AVAILABLE) || defined(OSG_GLES2_AVAILABLE) || defined(OSG_GLES3_AVAILABLE)      
        OE_WARN << "no glTexImage1D() in GLES \n";
#else

#endif

```sh
#   /data/user/0/com.example.androioearthdemo/files/readymap.earth
~/osgearth0x$ adb devices
List of devices attached
3054854792003E9	device
emulator-5554	device


(base) ~/osgearth0x$ adb -s 3054854792003E9 shell
PD2106:/ $  
PD2106:/ $ run-as com.example.androioearthdemo
PD2106:/data/user/0/com.example.androioearthdemo $ ls
cache  code_cache  files  lldb
PD2106:/data/user/0/com.example.androioearthdemo $ cd  files/  
PD2106:/data/user/0/com.example.androioearthdemo/files $ ls
readymap.earth

# Q2：如何修改 readymap.earth？​​
# 在电脑上编辑文件后，通过 adb push传回手机：
adb push ~/Desktop/readymap.earth /sdcard/
adb shell
run-as com.example.androioearthdemo
cp /sdcard/readymap.earth /data/user/0/com.example.androioearthdemo/files/
```


```sh 
# adb  logcat
adb -s 3054854792003E9 logcat | grep -E "osgEarth|OSG|OpenGL|EGL|Failed"
adb -s 3054854792003E9 logcat | grep -E "GL_ERROR"

adb -s emulator-5554 logcat | grep -E "osgEarth|OSG|OpenGL|EGL|Failed"
```