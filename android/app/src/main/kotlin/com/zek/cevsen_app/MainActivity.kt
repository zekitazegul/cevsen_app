package com.zek.cevsen_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.content.ClipData
import android.view.WindowManager
import androidx.core.content.FileProvider
import java.io.File

class MainActivity : FlutterActivity() {
    private lateinit var updater: AppUpdater

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (::updater.isInitialized) updater.onActivityResult(requestCode)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.zek.cevsen_app/screen")
            .setMethodCallHandler { call, result ->
                if (call.method != "setKeepScreenOn") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (call.argument<Boolean>("enabled") == true) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
                result.success(null)
            }
        updater = AppUpdater(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.zek.cevsen_app/update"))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.zek.cevsen_app/external")
            .setMethodCallHandler { call, result ->
                if (call.method == "audioDirectory") {
                    result.success(File(filesDir, "audio-v1").absolutePath)
                    return@setMethodCallHandler
                }
                if (call.method == "shareInstaller") {
                    Thread {
                        try {
                            val folder = File(cacheDir, "shared-apk").apply { mkdirs() }
                            val apk = File(folder, "Cevsen-Installer.apk")
                            val temporary = File(folder, "preparing.tmp")
                            assets.open("Cevsen-Installer.apk").use { input ->
                                temporary.outputStream().use { output -> input.copyTo(output) }
                            }
                            if (apk.exists() && !apk.delete()) throw IllegalStateException("Old APK unavailable")
                            if (!temporary.renameTo(apk)) throw IllegalStateException("APK unavailable")
                            val uri = FileProvider.getUriForFile(this, "$packageName.apkshare", apk)
                            runOnUiThread {
                                try {
                                    val intent = Intent(Intent.ACTION_SEND).apply {
                                        type = "application/vnd.android.package-archive"
                                        putExtra(Intent.EXTRA_STREAM, uri)
                                        putExtra(Intent.EXTRA_SUBJECT, "Cevsen Installer")
                                        clipData = ClipData.newRawUri("Cevsen Installer", uri)
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    }
                                    startActivity(Intent.createChooser(intent, "Cevsen Installer’ı paylaş"))
                                    result.success(null)
                                } catch (e: Exception) {
                                    result.error("share", "Paylaşım menüsü açılamadı.", null)
                                }
                            }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("apk", "Kurulum dosyası hazırlanamadı. Cihazdaki boş alanı kontrol et.", null) }
                        }
                    }.start()
                    return@setMethodCallHandler
                }
                if (call.method != "openUrl") { result.notImplemented(); return@setMethodCallHandler }
                val uri = Uri.parse(call.argument<String>("url") ?: "")
                val allowed = uri.scheme == "https" && uri.host in setOf("zekitazegul.github.io", "tikkie.me", "nurulkuran.com", "herkul.org", "github.com")
                if (!allowed) { result.error("url", "Unsupported link", null); return@setMethodCallHandler }
                try {
                    startActivity(Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE))
                    result.success(null)
                } catch (e: Exception) { result.error("open", "No browser available", null) }
            }
    }
}
