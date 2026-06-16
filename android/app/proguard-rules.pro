# Konecta — ProGuard / R8 Rules
# Pedro Espinal — Todos los derechos reservados 2026
# Este archivo protege la aplicacion contra ingenieria inversa

# ─── Flutter y Dart ──────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes InnerClasses,EnclosingMethod

# ─── Konecta core ────────────────────────────────────────────────
-keep class com.pedroespinal.konecta.** { *; }
-keepclassmembers class com.pedroespinal.konecta.** { *; }

# ─── Kotlin ──────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

# ─── WebRTC ──────────────────────────────────────────────────────
-keep class org.webrtc.** { *; }
-keepclassmembers class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# ─── Cifrado ─────────────────────────────────────────────────────
-keep class javax.crypto.** { *; }
-keep class java.security.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# ─── Flutter Secure Storage / Keystore ───────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ─── Local Auth / Biometria ──────────────────────────────────────
-keep class io.flutter.plugins.localauth.** { *; }
-keep class androidx.biometric.** { *; }

# ─── Firebase (si se agrega) ─────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# ─── SQLite ──────────────────────────────────────────────────────
-keep class org.sqlite.** { *; }

# ─── Permission Handler ──────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }

# ─── Record (audio) ──────────────────────────────────────────────
-keep class com.llfbandit.record.** { *; }
-dontwarn com.llfbandit.record.**

# ─── Ofuscacion agresiva ─────────────────────────────────────────
# Eliminar logs de debug en produccion
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
}

# Eliminar clases de reflexion peligrosas
-dontwarn java.lang.reflect.**
-dontwarn sun.misc.**
-dontwarn java.nio.file.**

# Eliminar informacion de debugging en produccion
-renamesourcefileattribute SourceFile

# ─── Anti-tampering ──────────────────────────────────────────────
# Ofuscar nombres de metodos y campos en clases de seguridad
-obfuscationdictionary proguard-dict.txt
-classobfuscationdictionary proguard-dict.txt
-packageobfuscationdictionary proguard-dict.txt
