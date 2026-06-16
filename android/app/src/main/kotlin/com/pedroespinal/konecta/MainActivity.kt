package com.pedroespinal.konecta

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Debug
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File

class MainActivity : FlutterActivity() {

    private val SECURITY_CHANNEL = "com.pedroespinal.konecta/security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SECURITY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isRooted" -> result.success(isRooted())
                "isFridaDetected" -> result.success(isFridaDetected())
                "isDebugged" -> result.success(isDebugged())
                else -> result.notImplemented()
            }
        }
    }

    // ─── Root Detection ─────────────────────────────────────────────

    private fun isRooted(): Boolean {
        return checkBuildTags()
            || checkSuBinaries()
            || checkRootPackages()
            || checkMagiskManager()
            || checkDangerousProps()
    }

    private fun checkBuildTags(): Boolean {
        val tags = Build.TAGS ?: return false
        return tags.contains("test-keys")
    }

    private fun checkSuBinaries(): Boolean {
        val paths = arrayOf(
            "/system/bin/su", "/system/xbin/su",
            "/sbin/su", "/data/local/su",
            "/data/local/bin/su", "/data/local/xbin/su",
            "/system/sd/xbin/su", "/system/bin/failsafe/su",
            "/data/local/tmp/su", "/system/xbin/daemonsu"
        )
        return paths.any { File(it).exists() }
    }

    private fun checkRootPackages(): Boolean {
        val pkgs = arrayOf(
            "com.noshufou.android.su",
            "com.noshufou.android.su.elite",
            "eu.chainfire.supersu",
            "com.koushikdutta.superuser",
            "com.thirdparty.superuser",
            "com.yellowes.su",
            "com.topjohnwu.magisk"
        )
        val pm: PackageManager = packageManager
        return pkgs.any { pkg ->
            try {
                pm.getPackageInfo(pkg, 0)
                true
            } catch (e: PackageManager.NameNotFoundException) {
                false
            }
        }
    }

    private fun checkMagiskManager(): Boolean {
        // Magisk puede ocultarse, pero deja rastros en /proc
        return try {
            val maps = File("/proc/1/maps")
            if (!maps.exists()) return false
            val content = maps.readText()
            content.contains("magisk", ignoreCase = true)
        } catch (e: Exception) {
            false
        }
    }

    private fun checkDangerousProps(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("getprop"))
            val reader = BufferedReader(java.io.InputStreamReader(process.inputStream))
            var line: String?
            var found = false
            while (reader.readLine().also { line = it } != null) {
                val l = line ?: continue
                if (l.contains("ro.debuggable") && l.contains("[1]")) {
                    found = true
                    break
                }
                if (l.contains("service.adb.root") && l.contains("[1]")) {
                    found = true
                    break
                }
            }
            reader.close()
            found
        } catch (e: Exception) {
            false
        }
    }

    // ─── Frida Detection ────────────────────────────────────────────

    private fun isFridaDetected(): Boolean {
        return checkFridaInMaps()
            || checkXposedInstalled()
            || checkFridaTracers()
    }

    private fun checkFridaInMaps(): Boolean {
        return try {
            val mapsFile = File("/proc/self/maps")
            if (!mapsFile.exists()) return false
            val content = mapsFile.readText().lowercase()
            val fridaPatterns = listOf(
                "frida-agent", "frida-gadget", "frida-inject",
                "gum-js-loop", "linjector"
            )
            fridaPatterns.any { content.contains(it) }
        } catch (e: Exception) {
            false
        }
    }

    private fun checkXposedInstalled(): Boolean {
        val xposedPkgs = arrayOf(
            "de.robv.android.xposed.installer",
            "com.saurik.substrate"
        )
        val pm: PackageManager = packageManager
        return xposedPkgs.any { pkg ->
            try {
                pm.getPackageInfo(pkg, 0)
                true
            } catch (e: PackageManager.NameNotFoundException) {
                false
            }
        }
    }

    private fun checkFridaTracers(): Boolean {
        return try {
            val statusFile = File("/proc/self/status")
            if (!statusFile.exists()) return false
            val content = statusFile.readText()
            val tracerLine = content.lines()
                .firstOrNull { it.startsWith("TracerPid:") } ?: return false
            val pid = tracerLine.substringAfter(":").trim().toIntOrNull() ?: 0
            pid != 0
        } catch (e: Exception) {
            false
        }
    }

    // ─── Debugger Detection ─────────────────────────────────────────

    private fun isDebugged(): Boolean {
        return Debug.isDebuggerConnected()
            || Debug.waitingForDebugger()
            || (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }
}
