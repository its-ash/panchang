package com.itsash.panchang

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Dart sends the next ~30 days of panchang as one JSON string for the home-screen widget.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.itsash.panchang/widget")
            .setMethodCallHandler { call, result ->
                val json = call.arguments as? String
                if (call.method == "update" && json != null) {
                    PanchangWidget.save(applicationContext, json)
                    PanchangWidget.updateAll(applicationContext)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
