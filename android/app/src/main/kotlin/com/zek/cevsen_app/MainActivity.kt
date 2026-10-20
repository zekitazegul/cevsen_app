package com.zek.cevsen_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.content.ClipData
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
        updater = AppUpdater(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.zek.cevsen_app/update"))
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.zek.cevsen_app/external")
            .setMethodCallHandler { call, result ->
                if (call.method == "shareApk") {
                    if (!applicationInfo.splitSourceDirs.isNullOrEmpty()) {
                        result.error("split", "Bu kurulum birden fazla APK içeriyor; tek dosya olarak paylaşılamıyor.", null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        try {
                            val folder = File(cacheDir, "shared-apk").apply { mkdirs() }
                            val version = packageManager.getPackageInfo(packageName, 0).versionName ?: "1"
                            val safeVersion = version.replace(Regex("[^A-Za-z0-9._-]"), "_")
                            val apk = File(folder, "Cevsen-$safeVersion.apk")
                            val temporary = File(folder, "preparing.tmp")
                            File(applicationInfo.sourceDir).copyTo(temporary, overwrite = true)
                            if (apk.exists() && !apk.delete()) throw IllegalStateException("Old APK unavailable")
                            if (!temporary.renameTo(apk)) throw IllegalStateException("APK unavailable")
                            val uri = FileProvider.getUriForFile(this, "$packageName.apkshare", apk)
                            runOnUiThread {
                                try {
                                    val intent = Intent(Intent.ACTION_SEND).apply {
                                        type = "application/vnd.android.package-archive"
                                        putExtra(Intent.EXTRA_STREAM, uri)
                                        putExtra(Intent.EXTRA_SUBJECT, "Cevşen $version")
                                        clipData = ClipData.newRawUri("Cevşen APK", uri)
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    }
                                    startActivity(Intent.createChooser(intent, "Cevşen uygulamasını paylaş"))
                                    result.success(null)
                                } catch (e: Exception) {
                                    result.error("share", "Paylaşım menüsü açılamadı.", null)
                                }
                            }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("apk", "APK hazırlanamadı. Cihazdaki boş alanı kontrol et.", null) }
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
