package com.rakshak.ai

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import kotlin.math.max

class UsageStatsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var sensorManager: SensorManager? = null
    private var lightSensor: Sensor? = null
    private var currentLux: Float = -1f

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "rakshak.ai/usage_stats")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
        initLightSensor()
    }

    private fun initLightSensor() {
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        lightSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT)

        lightSensor?.let { sensor ->
            sensorManager?.registerListener(object : SensorEventListener {
                override fun onSensorChanged(event: SensorEvent) {
                    currentLux = event.values[0]
                }
                override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
            }, sensor, SensorManager.SENSOR_DELAY_NORMAL)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getUsageStats" -> {
                val stats = getDetailedUsageStats()
                result.success(stats)
            }
            "hasPermission" -> {
                result.success(hasUsageStatsPermission())
            }
            "requestPermission" -> {
                requestUsageStatsPermission()
                result.success(null)
            }
            "getAmbientLux" -> {
                result.success(currentLux.toDouble())
            }
            "cacheStressScore" -> {
                val score = call.argument<Int>("score") ?: 0
                val riskLevel = call.argument<String>("risk_level") ?: "low"
                val timestamp = call.argument<String>("timestamp") ?: ""
                cacheStressScore(score, riskLevel, timestamp)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    private fun getDetailedUsageStats(): Map<String, Any> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, -1) // Last 24 hours
        val startTime = calendar.timeInMillis

        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        // Indian social media apps categorization
        val socialApps = setOf(
            "com.whatsapp",
            "com.instagram.android",
            "com.facebook.katana",
            "com.snapchat.android",
            "com.twitter.android",
            "com.zhiliaoapp.musically", // TikTok
            "com.ss.android.ugc.trill", // TikTok India
            "com.reddit.frontpage",
            "com.linkedin.android",
            "com.pinterest",
            "in.mohalla.sharechat",
            "com.takatak.app"
        )

        var totalScreenTime = 0L
        var socialMediaTime = 0L
        var pickupCount = 0
        var lateNightUsage = false
        var doomScrollFlag = false
        var longestSocialSession = 0L

        usageStats?.forEach { stat ->
            totalScreenTime += stat.totalTimeInForeground

            if (socialApps.contains(stat.packageName)) {
                socialMediaTime += stat.totalTimeInForeground
                longestSocialSession = max(longestSocialSession, stat.totalTimeInForeground)
            }

            // Estimate pickups from app launch count
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // This is approximate
                pickupCount += 1
            }

            // Check for late-night usage (12 AM - 4 AM)
            if (stat.lastTimeUsed in getLateNightRange()) {
                lateNightUsage = true
            }
        }

        // Doom scrolling detection: >20 min continuous social use
        if (longestSocialSession > 20 * 60 * 1000) {
            doomScrollFlag = true
        }

        return mapOf(
            "social_minutes" to (socialMediaTime / (1000 * 60)).toInt(),
            "pickup_count" to pickupCount,
            "late_night_usage" to lateNightUsage,
            "doom_scroll_flag" to doomScrollFlag,
            "total_screen_minutes" to (totalScreenTime / (1000 * 60)).toInt()
        )
    }

    private fun getLateNightRange(): LongRange {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        val midnight = calendar.timeInMillis
        
        calendar.set(Calendar.HOUR_OF_DAY, 4)
        val fourAM = calendar.timeInMillis
        
        return midnight..fourAM
    }

    private fun cacheStressScore(score: Int, riskLevel: String, timestamp: String) {
        val prefs = context.getSharedPreferences("rakshak_cache", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putInt("last_stress_score", score)
            putString("last_risk_level", riskLevel)
            putString("last_timestamp", timestamp)
            apply()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        sensorManager?.unregisterListener(object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {}
            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
        })
    }
}
