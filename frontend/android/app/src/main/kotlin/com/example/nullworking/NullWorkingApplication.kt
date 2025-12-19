package com.example.nullworking

import android.app.Application
import android.util.Log
import com.fm.openinstall.OpenInstall

class NullWorkingApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // OpenInstall 预初始化（可选，通常在 Application 中进行）
        OpenInstall.preInit(this)

        // OpenInstall 完整初始化
        // 注意：首次启动，确保用户同意《隐私政策》之后，再初始化openinstall SDK
        // 仅在主进程的UI线程中调用初始化接口，多进程调用将会导致获取参数失败，统计数据异常
        // 初始化调用时，尽量保证应用处于前台可触控状态下，对提升参数还原精度有很大的帮助
        OpenInstall.init(this)

        Log.d("OpenInstall", "SDK initialized")
    }
}