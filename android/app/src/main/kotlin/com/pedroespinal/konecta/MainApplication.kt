package com.pedroespinal.konecta

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build

class MainApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    // Crear el canal aquí (en Application) garantiza que exista ANTES de que llegue
    // cualquier FCM push, incluso cuando la app está completamente cerrada (killed).
    // Si el canal no existe cuando llega una notificación FCM, Android la descarta
    // silenciosamente en Android 8+.
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "konecta_messages",
                "Mensajes de Konecta",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notificaciones de mensajes nuevos"
                enableVibration(true)
                enableLights(true)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}
