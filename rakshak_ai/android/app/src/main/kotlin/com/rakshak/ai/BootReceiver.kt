package com.rakshak.ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * BootReceiver — Re-registers WorkManager periodic tasks after device reboot.
 * Ensures continuous background monitoring survives device restarts.
 *
 * Registered in AndroidManifest.xml for:
 *  - android.intent.action.BOOT_COMPLETED
 *  - android.intent.action.QUICKBOOT_POWERON
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "RakshakBootReceiver"
        private const val WORK_NAME = "rakshak_monitoring_task"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            Log.i(TAG, "Device booted — re-registering periodic monitoring task")
            registerPeriodicTask(context)
        }
    }

    private fun registerPeriodicTask(context: Context) {
        try {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
                .setRequiresBatteryNotLow(true)
                .build()

            val workRequest = PeriodicWorkRequestBuilder<RakshakWorker>(
                4, TimeUnit.HOURS, // repeat every 4 hours
                30, TimeUnit.MINUTES  // flex interval
            )
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                workRequest
            )

            Log.i(TAG, "Periodic monitoring task re-registered successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to re-register periodic task: ${e.message}")
        }
    }
}
