package com.oearth.androioearth01;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.view.Window;
import android.view.WindowManager;
import android.util.Log;


public class osgEarthViewer extends Activity 
{
    // Used to load the 'androioearth01' library on application startup.
    
    static {
        //System.loadLibrary("c++_shared");  // 先加载依赖库
        //System.loadLibrary("androioearth01");  // 再加载主库
          try {
              // 先尝试加载 ASan 库
              System.loadLibrary("clang_rt.asan-arm-android");
          } catch (UnsatisfiedLinkError e) {
              Log.w("ASAN", "ASan library load warning: " + e.getMessage());
              // 继续执行，让 wrap.sh 处理
          }


         try {
             // 然后加载主库
             System.loadLibrary("androioearth01");
         } catch (UnsatisfiedLinkError e) {
             Log.e("Native", "Failed to load native library: " + e.getMessage());
             throw e;
         }
    }
	
	private static final String TAG = "OSG Activity";
    EGLview mView;

    //Main Android Activity life cycle
    @Override protected void onCreate(Bundle icicle) 
    {
        Log.d(TAG, "^-^::::::osgEarthViewer::onCreate(Bundle icicle)..........");
    	//load our native lib
//        System.loadLibrary("androioearth01");

        super.onCreate(icicle);
        
        //set window style
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, 
                             WindowManager.LayoutParams.FLAG_FULLSCREEN);

        //set the data dirs string for android platform
        Context context = getApplicationContext(); // or other way of getting current context
        String dir = context.getFilesDir().getPath();
        String packageDir = context.getPackageResourcePath();
        osgNativeLib.setDataFilePath(dir, packageDir);
        
        // Create our GLSurfaceview EGLView which calls our native libs init and frame/update functions  
        mView = new EGLview(this);
        setContentView(mView);
    }

    @Override
    protected void onPause() 
    {
        super.onPause();
        mView.onPause();
    }
    @Override protected void onResume() 
    {
        super.onResume();
        mView.onResume();
    }
}