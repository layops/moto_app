package com.example.motoapp_frontend

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val CHANNEL = "deep_links"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Setup method channel for deep links
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    val initialLink = getInitialLink()
                    result.success(initialLink)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // EGL optimizations to reduce HWUI warnings
        window.setFlags(
            android.view.WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            android.view.WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        )
        
        // Handle initial intent
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        intent?.data?.let { uri ->
            if (uri.scheme == "motoapp" || 
                (uri.scheme == "https" && uri.host == "spiride.onrender.com" && uri.path?.startsWith("/api/users/auth/callback/") == true)) {
                methodChannel?.invokeMethod("onDeepLink", uri.toString())
            }
        }
    }
    
    private fun getInitialLink(): String? {
        val intent = intent
        val uri = intent.data
        return if (uri != null && (uri.scheme == "motoapp" || 
                (uri.scheme == "https" && uri.host == "spiride.onrender.com" && uri.path?.startsWith("/api/users/auth/callback/") == true))) {
            uri.toString()
        } else null
    }
}
