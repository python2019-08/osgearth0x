package com.oearth.androioearth01;

public class osgNativeLib {
    public static native void 		init(int width, int height);
    public static native void 		step();
    public static native void 		touchBeganEvent(int touchid, float x,float y);
    public static native void 		touchMovedEvent(int touchid, float x,float y);
    public static native void       touchZoomEvent(double delta);
    public static native void       touchRotationEvent(double aDelta);
    public static native void 		touchEndedEvent(int touchid, float x,float y, int tapcount);
    
    public static native void 		mouseButtonPressEvent(float x,float y, int button);
    public static native void 		mouseButtonReleaseEvent(float x,float y, int button);
    public static native void 		mouseMoveEvent(float x,float y);

    public static native void 		clearEventQueue();
    public static native void 		setDataFilePath(String dataPath, String packagePath);
}