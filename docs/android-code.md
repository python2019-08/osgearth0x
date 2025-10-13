# 1.Android 四大组件

Android 四大组件是 Android 应用程序的基础构建模块，每个组件都有特定的用途和生命周期。
 
## 四大组件对比

| 组件 | 用途 | 是否有UI | 启动方式 |
|------|------|----------|----------|
| Activity | 用户界面 | 是 | Intent |
| Service | 后台任务 | 否 | Intent或绑定 |
| Broadcast Receiver | 事件响应 | 否 | 广播 |
| Content Provider | 数据共享 | 否 | ContentResolver |

## 组件间的通信

### Intent（意图）
```java
// 启动Activity
Intent intent = new Intent(this, TargetActivity.class);
startActivity(intent);

// 启动Service
Intent serviceIntent = new Intent(this, MyService.class);
startService(serviceIntent);

// 发送广播
Intent broadcastIntent = new Intent("CUSTOM_ACTION");
sendBroadcast(broadcastIntent);
```

### 数据访问
```java
// 通过Content Provider访问数据
Cursor cursor = getContentResolver().query(
    Uri.parse("content://com.example.provider/users"),
    null, null, null, null
);
```

## 生命周期管理

每个组件都有特定的生命周期，由 Android 系统管理：
- **Activity**：可见性变化（创建、启动、恢复、暂停、停止、销毁）
- **Service**：服务状态（创建、启动、绑定、销毁）
- **Broadcast Receiver**：仅在接收广播时活跃
- **Content Provider**：在查询时激活

## 实际应用示例

```xml
<!-- AndroidManifest.xml 中的完整声明 -->
<application>
    <!-- Activity -->
    <activity android:name=".MainActivity"
        android:exported="true">
        <intent-filter>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent-filter>
    </activity>
    
    <!-- Service -->
    <service android:name=".DownloadService" />
    
    <!-- Broadcast Receiver -->
    <receiver android:name=".NetworkReceiver">
        <intent-filter>
            <action android:name="android.net.conn.CONNECTIVITY_CHANGE" />
        </intent-filter>
    </receiver>
    
    <!-- Content Provider -->
    <provider 
        android:name=".DataProvider"
        android:authorities="com.example.app.dataprovider"
        android:exported="false" />
</application>
```

这四大组件共同构成了 Android 应用的基础架构，通过它们可以构建功能丰富的移动应用程序。