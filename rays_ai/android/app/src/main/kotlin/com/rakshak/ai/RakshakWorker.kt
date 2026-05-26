package com.rakshak.ai

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * RakshakWorker — Native WorkManager worker that bootstraps Flutter engine
 * for background execution after device reboot. This is the Java/Kotlin side
 * of the WorkManager integration. The Flutter callbackDispatcher handles
 * the actual data collection and ML inference.
 */
class RakshakWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    companion object {
        private const val TAG = "RakshakWorker"
    }

    override fun doWork(): Result {
        return try {
            Log.i(TAG, "RakshakWorker executing background task")
            // The actual work is delegated to Flutter's WorkManager callback
            // via the flutter_workmanager plugin. This native worker exists
            // as a fallback for the BootReceiver re-registration path.
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Worker failed: ${e.message}")
            Result.retry()
        }
    }
}
