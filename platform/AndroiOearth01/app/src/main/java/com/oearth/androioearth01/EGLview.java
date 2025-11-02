package com.oearth.androioearth01;

import android.content.Context;
import android.graphics.PixelFormat;
import android.opengl.GLSurfaceView;
import android.util.AttributeSet;
import android.util.Log;
import android.view.*;
import android.graphics.Color;
import android.graphics.PointF;

import javax.microedition.khronos.egl.EGL10;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.egl.EGLContext;
import javax.microedition.khronos.egl.EGLDisplay;
import javax.microedition.khronos.opengles.GL10;
import java.lang.Math;


public class EGLview extends GLSurfaceView 
{
	private static String TAG = "EGLview";
	private static final boolean DEBUG = false;
	
	int mTouchState;
	final int ETouchState_IDLE = 0;
	final int ETouchState_OneFinger = 1;
	final int ETouchState_TwoFinger = 2;

    // enum moveTypes { NONE , DRAG, MDRAG, ZOOM ,ACTUALIZE}
	private GestureDetector gestureDetector;
	private ScaleGestureDetector scaleGestureDetector;
     
	static int mTapcount = 1;
	double mDist0 = 1;
	double mDistCurrent = 1;
	double mDistOld = 1;

	double mRotateAngle0 = 1;//in radians
	double mRotateAngleCur = 1;
	double mRotateAngleOld = 1;
	
	public EGLview(Context context) {
	    super(context);
	    init(context, true, 24, 8);
	}
	public EGLview(Context context, AttributeSet attrs) {
	    super(context,attrs);
	    init(context, true, 24, 8);
	}
	
	public EGLview(Context context, boolean translucent, int depth, int stencil) 
	{
	    super(context);
	    init(context, translucent, depth, stencil);
	}
	
	private void init(Context context, boolean translucent, int depth, int stencil) 
	{
	    if (translucent) {
	        this.getHolder().setFormat(PixelFormat.TRANSLUCENT);
	    }

	    setEGLContextFactory(new ContextFactory());

	    setEGLConfigChooser(translucent ?
				new ConfigChooser(8, 8, 8, 8, depth, stencil) :
				new ConfigChooser(5, 6, 5, 0, depth, stencil));
	
	    /* Set the renderer responsible for frame rendering */
	    setRenderer(new Renderer());

		this.setOnTouchListener(mOnTouchListener);
	}
	// -------------------------------------------------
	private static class ContextFactory implements GLSurfaceView.EGLContextFactory 
	{
	    private static int EGL_CONTEXT_CLIENT_VERSION = 0x3098;
	    public EGLContext createContext(EGL10 egl, EGLDisplay display, EGLConfig eglConfig) 
		{
            Log.w(TAG, "creating OpenGL ES 3.0 context");
            checkEglError("Before eglCreateContext", egl);
	        int[] attrib_list = {EGL_CONTEXT_CLIENT_VERSION, 3, EGL10.EGL_NONE };
	        EGLContext context = egl.eglCreateContext(display, eglConfig, 
					EGL10.EGL_NO_CONTEXT, attrib_list);
	        checkEglError("After eglCreateContext", egl);
	        return context;
	    }
	
	    public void destroyContext(EGL10 egl, EGLDisplay display, EGLContext context) 
		{
	        egl.eglDestroyContext(display, context);
	    }
	}
	// -------------------------------------------------
	private static void checkEglError(String prompt, EGL10 egl) 
	{
	    int error;
	    while ((error = egl.eglGetError()) != EGL10.EGL_SUCCESS) 
		{
	        Log.e(TAG, String.format("%s: EGL error: 0x%x", prompt, error));
	    }
	}
	// -------------------------------------------------
	private static class ConfigChooser implements GLSurfaceView.EGLConfigChooser 
	{
	
	    public ConfigChooser(int r, int g, int b, int a, int depth, int stencil) 
		{
	        mRedSize = r;
	        mGreenSize = g;
	        mBlueSize = b;
	        mAlphaSize = a;
	        mDepthSize = depth;
	        mStencilSize = stencil;
	    }
	
	    /* This EGL config specification is used to specify 1.x rendering.
	     * We use a minimum size of 4 bits for red/green/blue, but will
	     * perform actual matching in chooseConfig() below.
	     */
	    private static int EGL_OPENGL_ES3_BIT = 0x0040;
	    private static int[] s_configAttribs2 =
	    {
	        EGL10.EGL_RED_SIZE, 4,
	        EGL10.EGL_GREEN_SIZE, 4,
	        EGL10.EGL_BLUE_SIZE, 4,
	        EGL10.EGL_RENDERABLE_TYPE, EGL_OPENGL_ES3_BIT,
	        EGL10.EGL_NONE
	    };
	    private static final int EGL_DEPTH_ENCODING_NV      = 0x30E2;
	    private static final int EGL_DEPTH_ENCODING_NONLINEAR_NV = 0x30E3;
	
	    public EGLConfig chooseConfig(EGL10 egl, EGLDisplay display) 
		{
	        /* Get the number of minimally matching EGL configurations
	         */
	        int[] num_config = new int[1];
	        egl.eglChooseConfig(display, s_configAttribs2, null, 0, num_config);
	
	        int numConfigs = num_config[0];
	
	        if (numConfigs <= 0) {
	            throw new IllegalArgumentException("No configs match configSpec");
	        }
	
	        /* Allocate then read the array of minimally matching EGL configs
	         */
	        EGLConfig[] configs = new EGLConfig[numConfigs];
	        egl.eglChooseConfig(display, s_configAttribs2, configs, numConfigs, num_config);
	
	        if (DEBUG) {
	             printConfigs(egl, display, configs);
	        }
	        /* Now return the "best" one
	         */
	        return chooseConfig(egl, display, configs);
	    }
	
	    public EGLConfig chooseConfig(EGL10 egl, EGLDisplay display,
	            EGLConfig[] configs) 
		{
	    	EGLConfig bestConfig = null; 
	        for(EGLConfig config : configs)
			{
	           
	        	 // We want an *exact* match for red/green/blue/alpha
	            int r = findConfigAttrib(egl, display, config,
	                    EGL10.EGL_RED_SIZE, 0);
	            int g = findConfigAttrib(egl, display, config,
	                        EGL10.EGL_GREEN_SIZE, 0);
	            int b = findConfigAttrib(egl, display, config,
	                        EGL10.EGL_BLUE_SIZE, 0);
	            int a = findConfigAttrib(egl, display, config,
	                    EGL10.EGL_ALPHA_SIZE, 0);
	
	            if (r != mRedSize || g != mGreenSize || b != mBlueSize || a != mAlphaSize)
	            	continue;
	        	
	            
	        	int d = findConfigAttrib(egl, display, config,
	                    EGL10.EGL_DEPTH_SIZE, 0);
	            int s = findConfigAttrib(egl, display, config,
	                    EGL10.EGL_STENCIL_SIZE, 0);
	
	            // We need at least mDepthSize and mStencilSize bits
	            if (d < mDepthSize || s < mStencilSize)
	                continue;
	            
	            if(bestConfig == null){
	            	bestConfig = config;
	            }
	            
	            //check for EGL_DEPTH_ENCODING_NV
	            int hasDepthNonLinear = findConfigAttrib(egl, display, config, EGL_DEPTH_ENCODING_NV, 0);
	            if(hasDepthNonLinear== EGL_DEPTH_ENCODING_NONLINEAR_NV)
	            	bestConfig = config;
	         
	        }//for(EGLConfig config : configs)
	        if(bestConfig == null && mDepthSize==24){
	        	mDepthSize = 16;
	        	return chooseConfig(egl, display, configs);
	        }
	        return bestConfig;
	    }
	
	    private int findConfigAttrib(EGL10 egl, EGLDisplay display,
	            EGLConfig config, int attribute, int defaultValue) 
		{
	        if (egl.eglGetConfigAttrib(display, config, attribute, mValue)) 
			{
	            return mValue[0];
	        }
	        return defaultValue;
	    }
	
	    private void printConfigs(EGL10 egl, EGLDisplay display,
	        EGLConfig[] configs) 
		{
	        int numConfigs = configs.length;
	        Log.w(TAG, String.format("%d configurations", numConfigs));

	        for (int i = 0; i < numConfigs; i++) 
			{
	            Log.w(TAG, String.format("Configuration %d:\n", i));
	            printConfig(egl, display, configs[i]);
	        }
	    }
	
	    private void printConfig(EGL10 egl, EGLDisplay display,
	            EGLConfig config) 
		{
	        int[] attributes = {
	                EGL10.EGL_BUFFER_SIZE,
	                EGL10.EGL_ALPHA_SIZE,
	                EGL10.EGL_BLUE_SIZE,
	                EGL10.EGL_GREEN_SIZE,
	                EGL10.EGL_RED_SIZE,
	                EGL10.EGL_DEPTH_SIZE,
	                EGL10.EGL_STENCIL_SIZE,
	                EGL10.EGL_CONFIG_CAVEAT,
	                EGL10.EGL_CONFIG_ID,
	                EGL10.EGL_LEVEL,
	                EGL10.EGL_MAX_PBUFFER_HEIGHT,
	                EGL10.EGL_MAX_PBUFFER_PIXELS,
	                EGL10.EGL_MAX_PBUFFER_WIDTH,
	                EGL10.EGL_NATIVE_RENDERABLE,
	                EGL10.EGL_NATIVE_VISUAL_ID,
	                EGL10.EGL_NATIVE_VISUAL_TYPE,
	                0x3030, // EGL10.EGL_PRESERVED_RESOURCES,
	                EGL10.EGL_SAMPLES,
	                EGL10.EGL_SAMPLE_BUFFERS,
	                EGL10.EGL_SURFACE_TYPE,
	                EGL10.EGL_TRANSPARENT_TYPE,
	                EGL10.EGL_TRANSPARENT_RED_VALUE,
	                EGL10.EGL_TRANSPARENT_GREEN_VALUE,
	                EGL10.EGL_TRANSPARENT_BLUE_VALUE,
	                0x3039, // EGL10.EGL_BIND_TO_TEXTURE_RGB,
	                0x303A, // EGL10.EGL_BIND_TO_TEXTURE_RGBA,
	                0x303B, // EGL10.EGL_MIN_SWAP_INTERVAL,
	                0x303C, // EGL10.EGL_MAX_SWAP_INTERVAL,
	                EGL10.EGL_LUMINANCE_SIZE,
	                EGL10.EGL_ALPHA_MASK_SIZE,
	                EGL10.EGL_COLOR_BUFFER_TYPE,
	                EGL10.EGL_RENDERABLE_TYPE,
	                0x3042 // EGL10.EGL_CONFORMANT
	        };
	        String[] names = {
	                "EGL_BUFFER_SIZE",
	                "EGL_ALPHA_SIZE",
	                "EGL_BLUE_SIZE",
	                "EGL_GREEN_SIZE",
	                "EGL_RED_SIZE",
	                "EGL_DEPTH_SIZE",
	                "EGL_STENCIL_SIZE",
	                "EGL_CONFIG_CAVEAT",
	                "EGL_CONFIG_ID",
	                "EGL_LEVEL",
	                "EGL_MAX_PBUFFER_HEIGHT",
	                "EGL_MAX_PBUFFER_PIXELS",
	                "EGL_MAX_PBUFFER_WIDTH",
	                "EGL_NATIVE_RENDERABLE",
	                "EGL_NATIVE_VISUAL_ID",
	                "EGL_NATIVE_VISUAL_TYPE",
	                "EGL_PRESERVED_RESOURCES",
	                "EGL_SAMPLES",
	                "EGL_SAMPLE_BUFFERS",
	                "EGL_SURFACE_TYPE",
	                "EGL_TRANSPARENT_TYPE",
	                "EGL_TRANSPARENT_RED_VALUE",
	                "EGL_TRANSPARENT_GREEN_VALUE",
	                "EGL_TRANSPARENT_BLUE_VALUE",
	                "EGL_BIND_TO_TEXTURE_RGB",
	                "EGL_BIND_TO_TEXTURE_RGBA",
	                "EGL_MIN_SWAP_INTERVAL",
	                "EGL_MAX_SWAP_INTERVAL",
	                "EGL_LUMINANCE_SIZE",
	                "EGL_ALPHA_MASK_SIZE",
	                "EGL_COLOR_BUFFER_TYPE",
	                "EGL_RENDERABLE_TYPE",
	                "EGL_CONFORMANT"
	        };
	        int[] value = new int[1];
	        for (int i = 0; i < attributes.length; i++) 
			{
	            int attribute = attributes[i];
	            String name = names[i];
	            if ( egl.eglGetConfigAttrib(display, config, attribute, value)) 
				{
	                Log.w(TAG, String.format("  %s: %d\n", name, value[0]));
	            } else {
	                // Log.w(TAG, String.format("  %s: failed\n", name));
	                while (egl.eglGetError() != EGL10.EGL_SUCCESS);
	            }
	        }
	    }
	
	    // Subclasses can adjust these values:
	    protected int mRedSize;
	    protected int mGreenSize;
	    protected int mBlueSize;
	    protected int mAlphaSize;
	    protected int mDepthSize;
	    protected int mStencilSize;
	    private int[] mValue = new int[1];
	}
	
	// -------------------------------------------------
	private static class Renderer implements GLSurfaceView.Renderer 
	{
		
		public void onDrawFrame(GL10 gl)
		{
	        osgNativeLib.step();
	    }
	
	    public void onSurfaceChanged(GL10 gl, int width, int height) {
	    	osgNativeLib.init(width, height);
	    }
	
	    @Override
	    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
	        	gl.glEnable(GL10.GL_DEPTH_TEST);
		}
	}

	// -------------------------------------------------
	OnTouchListener mOnTouchListener = new OnTouchListener() 
	{
		@Override
		public boolean onTouch(View v, MotionEvent event) 
		{
			switch(event.getAction() & MotionEvent.ACTION_MASK) 
			{
				case MotionEvent.ACTION_DOWN:
					mTouchState = ETouchState_OneFinger;
					int touchID = event.getPointerId(0);
					osgNativeLib.touchBeganEvent(touchID, event.getX(), event.getY());
					break;
				case MotionEvent.ACTION_POINTER_DOWN:
				{
					mTouchState = ETouchState_TwoFinger;

					float diffX = event.getX(0) - event.getX(1);
					float diffY = event.getY(0) - event.getY(1);
					//---- zoom 
					mDist0 = Math.sqrt(diffX * diffX + diffY * diffY);
					mDistOld = mDist0;
					//---- rotate
					mRotateAngle0 = Math.atan2(diffY, diffX);
					mRotateAngleOld = mRotateAngle0;
				}
					break;
				case MotionEvent.ACTION_MOVE:
					// if (缩放和旋转同时检测) {
					//     // 基于手势特征判断主导意图
					//     if (两指距离变化率 > 旋转角度变化率 × 2) {
					//         优先处理缩放，限制旋转;
					//     } else if (旋转角度 > 15° && 缩放变化 < 10%) {
					//         优先处理旋转，限制缩放;
					//     } else {
					//         // 混合处理：缩放为主，旋转为辅
					//         缩放系数 = 距离变化;
					//         旋转系数 = 角度变化 × (1 - 缩放权重);
					//     }
					// }
					if(mTouchState == ETouchState_TwoFinger) 
					{
						float diffX = event.getX(0) - event.getX(1);
						float diffY = event.getY(0) - event.getY(1);	

						//---- zoom 
						mDistCurrent = Math.sqrt(diffX * diffX + diffY * diffY);
						double zoomDelta =  -1 * (1 - (mDistOld / mDistCurrent));	
						mDistOld = mDistCurrent;	


						//---- rotate
						mRotateAngleCur = Math.atan2(diffY, diffX);
						double diffRadians =  -(mRotateAngleCur - mRotateAngleOld);
						double rotationDegreesDelta =Math.abs (diffRadians * 180 / Math.PI) ;
						mRotateAngleOld = mRotateAngleCur;
						Log.i("androioearth01","rotationDegreesDelta="+rotationDegreesDelta+";zoomDelta="+zoomDelta);
						if (rotationDegreesDelta > 1.01 && Math.abs(zoomDelta) < 0.1){
							osgNativeLib.touchRotationEvent( diffRadians  );
						}else{
							osgNativeLib.touchZoomEvent( zoomDelta );
						}

					} 
					else 
					{						
						touchID = event.getPointerId(0);
						// final int historySize = event.getHistorySize();
						// for (int h = 0; h < historySize; h++) 
						// { 
						// 	osgNativeLib.touchMovedEvent(touchID, event.getHistoricalX(h), event.getHistoricalY(h));
						// }						
						osgNativeLib.touchMovedEvent(touchID, event.getX(), event.getY());
					}
					break;
				case MotionEvent.ACTION_UP:
					mTouchState = ETouchState_IDLE;
					touchID = event.getPointerId(0);
					osgNativeLib.clearEventQueue();
					osgNativeLib.touchEndedEvent(touchID, event.getX(), event.getY(), mTapcount);
					break;
				case MotionEvent.ACTION_POINTER_UP:
					mTouchState = ETouchState_IDLE;
					touchID = event.getPointerId(0);
					osgNativeLib.clearEventQueue();
					osgNativeLib.touchEndedEvent(touchID, event.getX(), event.getY(), mTapcount);
					break;
			}
			return true;
		}
		
	};	// END OnTouchListener mOnTouchListener = new OnTouchListener() 
		    
}

