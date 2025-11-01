package com.example.androioearthdemo;


import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.res.Resources;
import android.graphics.Color;
import android.graphics.PointF;
import android.os.Bundle;
import android.util.FloatMath;
import android.util.Log;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.WindowManager;
import android.view.View.OnClickListener;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ImageButton;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class osgViewer extends Activity implements View.OnTouchListener, View.OnKeyListener
{
    enum moveTypes { NONE , DRAG, MDRAG, ZOOM ,ACTUALIZE}
    enum navType { PRINCIPAL , SECONDARY }
    enum lightType { ON , OFF }

    moveTypes mMoveType=moveTypes.NONE;
    navType mNavMode = navType.PRINCIPAL;
    lightType lightMode = lightType.ON;

    PointF oneFingerOrigin = new PointF(0,0);
    long timeOneFinger=0;
    PointF twoFingerOrigin = new PointF(0,0);
    long timeTwoFinger=0;
    float distanceOrigin;

    private static final String TAG = "OSG Activity";
    //Ui elements
    EGLview mView;
    Button uiCenterViewButton;

    //Dialogs
    AlertDialog removeLayerDialog;
    AlertDialog loadLayerAddress;

    public static String mEarthPath = null;

    //Main Android Activity life cycle
    @Override protected void onCreate(Bundle icicle)
    {
        super.onCreate(icicle);
        setContentView(R.layout.ui_layout_gles);

//        // 检查 Ethernet 服务是否可用
//        boolean isEthernetOk = isEthernetSupported();
//        if(!isEthernetOk){
//            Log.d(TAG,"^-^::::::isEthernetOk==false");
//        }
        
        Log.d(TAG,"^-^:::::: onCreate(Bundle icicle) start.....................................");
        // get the gl view and attach touch listeners
        mView= (EGLview) findViewById(R.id.surfaceGLES);
        mView.setOnTouchListener(this);
        mView.setOnKeyListener(this);

        uiCenterViewButton = (Button) findViewById(R.id.uiButtonCenter);
        uiCenterViewButton.setOnClickListener(uiListenerCenterView);

        mEarthPath = copyAssetsToInternalStorage();

        File file = new File(mEarthPath);
        Log.e("PATH", "File exists: " + file.exists() + ", path: " + mEarthPath);
    }


    public String copyAssetsToInternalStorage() 
    {
        File internalFile = new File(getFilesDir(), "readymap.earth");

        try  
        {
            InputStream is = getAssets().open("readymap.earth");
            OutputStream os = new FileOutputStream(internalFile);

            
            byte[] buffer = new byte[1024];
            int length;
            while ((length = is.read(buffer)) > 0) 
            {
                os.write(buffer, 0, length);
            }


            return internalFile.getAbsolutePath();
        } catch (IOException e) {
            Log.e("OSG", "Failed to copy file", e);
            return null;
        }
    }


    @Override protected void onPause() {
        super.onPause();
        mView.onPause();
    }
    @Override protected void onResume() {
        super.onResume();
        mView.onResume();
    }

    //Main view event processing
    @Override
    public boolean onKey(View v, int keyCode, KeyEvent event) {
        return true;
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event)
    {
        //DO NOTHING this will render useless every menu key except Home
        int keyChar= event.getUnicodeChar();
        osgNativeLib.keyboardDown(keyChar);
        return true;
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event)
    {
        switch (keyCode)
        {
            case KeyEvent.KEYCODE_BACK:
                super.onDestroy();
                this.finish();
                break;
            case KeyEvent.KEYCODE_SEARCH:
                break;
            case KeyEvent.KEYCODE_MENU:
                this.openOptionsMenu();
                break;
            default:
                int keyChar= event.getUnicodeChar();
                osgNativeLib.keyboardUp(keyChar);
        }

        return true;
    }

    @Override
    public boolean onTouch(View v, MotionEvent event)
    {
        //dumpEvent(event);

        long time_arrival = event.getEventTime();
        int n_points = event.getPointerCount();
        int action = event.getAction() & MotionEvent.ACTION_MASK;


        if(1 == n_points)
        {
            float x0 = event.getX(0);
            float y0 = event.getY(0);

            switch (action)
            {
                case MotionEvent.ACTION_DOWN:
                    mMoveType = moveTypes.DRAG;

                    osgNativeLib.mouseMoveEvent(x0, y0);
                    if (mNavMode == navType.PRINCIPAL)
                        osgNativeLib.mouseButtonPressEvent(x0, y0, 2);
                    else
                        osgNativeLib.mouseButtonPressEvent(x0, y0, 1);

                    oneFingerOrigin.x = x0;
                    oneFingerOrigin.y = y0;
                    break;
                case MotionEvent.ACTION_CANCEL:
                    switch (mMoveType)
                    {
                        case DRAG:
                            osgNativeLib.mouseMoveEvent( x0, y0);
                            if (mNavMode == navType.PRINCIPAL)
                                osgNativeLib.mouseButtonReleaseEvent(x0, y0, 2);
                            else
                                osgNativeLib.mouseButtonReleaseEvent(x0, y0, 1);
                            break;
                        default:
                            Log.e(TAG, "There has been an anomaly in touch input 1point/action");
                    }
                    mMoveType = moveTypes.NONE;
                    break;
                case MotionEvent.ACTION_MOVE:

                    osgNativeLib.mouseMoveEvent( x0, y0);

                    oneFingerOrigin.x = x0;
                    oneFingerOrigin.y = y0;

                    break;
                case MotionEvent.ACTION_UP:
                    switch (mMoveType)
                    {
                        case DRAG:
                            if (mNavMode == navType.PRINCIPAL)
                                osgNativeLib.mouseButtonReleaseEvent(x0, y0, 2);
                            else
                                osgNativeLib.mouseButtonReleaseEvent(x0, y0, 1);
                            break;
                        default:
                            Log.e(TAG, "There has been an anomaly in touch input 1 point/action");
                    }
                    mMoveType = moveTypes.NONE;
                    break;
                default:
                    Log.e(TAG, "1 point Action not captured");
            }
        }
        else if(2 == n_points)
        {
            float x0 = event.getX(0);
            float y0 = event.getY(0);
            float x1 = event.getX(1);
            float y1 = event.getY(1);

            switch (action)
            {
                case MotionEvent.ACTION_POINTER_DOWN:
                    //Free previous Action
                    switch(mMoveType)
                    {
                        case DRAG:
                            if(mNavMode==navType.PRINCIPAL)
                                osgNativeLib.mouseButtonReleaseEvent(x0, y0, 2);
                            else
                                osgNativeLib.mouseButtonReleaseEvent(x0, y0, 1);
                            break;
                    }
                    mMoveType = moveTypes.ZOOM;
                    distanceOrigin = sqrDistance(event);
                    twoFingerOrigin.x = x1;
                    twoFingerOrigin.y = y1;
                    oneFingerOrigin.x = x0;
                    oneFingerOrigin.y = x0;

                    osgNativeLib.mouseMoveEvent(oneFingerOrigin.x,oneFingerOrigin.y);
                    osgNativeLib.mouseButtonPressEvent(oneFingerOrigin.x,oneFingerOrigin.y, 3);
                    osgNativeLib.mouseMoveEvent(oneFingerOrigin.x,oneFingerOrigin.y);

                case MotionEvent.ACTION_MOVE:
                    float distance = sqrDistance(event);
                    float result = distance-distanceOrigin;
                    distanceOrigin=distance;

                    if(result>1||result<-1){
                        oneFingerOrigin.y=oneFingerOrigin.y+result;
                        osgNativeLib.mouseMoveEvent(oneFingerOrigin.x,oneFingerOrigin.y);
                    }

                    break;
                case MotionEvent.ACTION_POINTER_UP:
                    mMoveType =moveTypes.NONE;
                    osgNativeLib.mouseButtonReleaseEvent(oneFingerOrigin.x,oneFingerOrigin.y, 3);
                    break;
                case MotionEvent.ACTION_UP:
                    mMoveType =moveTypes.NONE;
                    osgNativeLib.mouseButtonReleaseEvent(oneFingerOrigin.x,oneFingerOrigin.y, 3);
                    break;
                default :
                    Log.e(TAG,"2 point Action not captured");
            }
        }


        return true;
    }

    //Ui Listeners
    OnClickListener uiListenerCenterView = new OnClickListener()
    {
        public void onClick(View v) {
            //Log.d(TAG, "Center View");
            osgNativeLib.keyboardDown(32);
            osgNativeLib.keyboardUp(32);
        }
    };

    //Menu

    //Android Life Cycle Menu
    @Override
    public boolean onCreateOptionsMenu(Menu menu)
    {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.appmenu, menu);
        return super.onCreateOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item)
    {
        // Handle item selection
        switch (item.getItemId())
        {
//            case R.id.menuShowKeyboard:
//                Log.d(TAG,"Keyboard");
//                InputMethodManager mgr= (InputMethodManager)this.getSystemService(Context.INPUT_METHOD_SERVICE);
//                mgr.toggleSoftInput(InputMethodManager.SHOW_IMPLICIT, 0);
//                return true;
//            default:
//                return super.onOptionsItemSelected(item);
        }
        return  false;
    }

    //Utilities
    /** Show an event in the LogCat view, for debugging */
    private void dumpEvent(MotionEvent event)
    {
        String names[] = { "DOWN", "UP", "MOVE", "CANCEL", "OUTSIDE",
                "POINTER_DOWN", "POINTER_UP", "7?", "8?", "9?" };

        StringBuilder sb = new StringBuilder();
        int action = event.getAction();
        int actionCode = action & MotionEvent.ACTION_MASK;
        sb.append("event ACTION_").append(names[actionCode]);
        if (actionCode == MotionEvent.ACTION_POINTER_DOWN ||
            actionCode == MotionEvent.ACTION_POINTER_UP)
        {
            sb.append("(pid ").append(
                    action >> MotionEvent.ACTION_POINTER_ID_SHIFT);
            sb.append(")");
        }
        sb.append("[");

        for (int i = 0; i < event.getPointerCount(); i++)
        {
            sb.append("#").append(i);
            sb.append("(pid ").append(event.getPointerId(i));
            sb.append(")=").append((int) event.getX(i));
            sb.append(",").append((int) event.getY(i));

            if (i + 1 < event.getPointerCount())
                sb.append(";");
        }
        sb.append("]");
        //Log.d(TAG, sb.toString());
    }

    private float sqrDistance(MotionEvent event)
    {
        float x = event.getX(0) - event.getX(1);
        float y = event.getY(0) - event.getY(1);

        return (float)(Math.sqrt(x * x + y * y));
    }

//    // 检查 Ethernet 服务是否可用
//    public boolean isEthernetSupported()
//    {
//        try {
//            // 尝试通过反射获取ETHERNET_SERVICE常量
//            Field field = Context.class.getField("ETHERNET_SERVICE");
//            String ethernetService = (String) field.get(null);
//            return getSystemService(ethernetService) != null;
//        } catch (Exception e) {
//            // 如果获取失败，说明设备不支持以太网服务
//            return false;
//        }
//    }

}