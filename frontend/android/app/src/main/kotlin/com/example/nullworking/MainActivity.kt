package com.example.nullworking

import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.fm.openinstall.OpenInstall
import com.fm.openinstall.listener.AppWakeUpAdapter
import com.fm.openinstall.model.AppData
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.nullworking/openinstall"
    private var methodChannel: MethodChannel? = null
    private var pendingData: Any? = null

    // 使用 Adapter 替代 Listener 可以更稳定地处理双参数回调
    private val wakeupAdapter = object : AppWakeUpAdapter() {
        override fun onWakeUp(appData: AppData) {
            // 获取自定义参数数据
            val data = appData.data
            Log.d("OpenInstall", "唤醒成功，参数: $data")

            if (data != null) {
                // 如果 Flutter 端还没准备好，先暂存数据
                pendingData = data
                // 尝试发送给 Flutter
                runOnUiThread {
                    methodChannel?.invokeMethod("onWakeUp", data)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 初始化 MethodChannel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "getPendingData") {
                result.success(pendingData)
                pendingData = null // 发送后清空
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 第一次启动（冷启动）获取参数
        OpenInstall.getWakeUp(intent, wakeupAdapter)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // 必须调用 setIntent，否则在后台被唤醒时 getWakeUp 可能获取不到最新的 intent
        setIntent(intent)
        // App 在后台时被唤醒获取参数
        OpenInstall.getWakeUp(intent, wakeupAdapter)
    }

    override fun onDestroy() {
        methodChannel = null
        super.onDestroy()
    }
}
