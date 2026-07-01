package com.example.fakesms

import android.app.Service
import android.content.Intent
import android.os.IBinder

class HeadlessSmsSendService : Service() {
    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // This is a stub to satisfy Android's default SMS app requirements
        return START_NOT_STICKY
    }
}
