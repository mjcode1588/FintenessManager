package com.example.fintenessmanager

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper
import android.widget.Toast

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.fintenessmanager/back_button"
    private var backPressedTime: Long = 0
    private val backPressedInterval: Long = 2000 // 2 seconds

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "handleBackPressed" -> {
                    val currentTime = System.currentTimeMillis()
                    if (currentTime - backPressedTime > backPressedInterval) {
                        backPressedTime = currentTime
                        Toast.makeText(this, "뒤로가기 버튼을 한 번 더 누르면 앱이 종료됩니다", Toast.LENGTH_SHORT).show()
                        result.success(false)
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onBackPressed() {
        val methodChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.invokeMethod("onBackPressed", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (result == true) {
                    super@MainActivity.onBackPressed()
                }
            }
            
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                super@MainActivity.onBackPressed()
            }
            
            override fun notImplemented() {
                super@MainActivity.onBackPressed()
            }
        })
    }
}
