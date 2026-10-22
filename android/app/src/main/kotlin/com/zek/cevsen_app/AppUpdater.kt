package com.zek.cevsen_app

import android.content.Intent
import android.app.AlertDialog
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.content.pm.PackageManager
import android.content.pm.PackageInfo
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.io.ByteArrayOutputStream
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.CountDownLatch
import java.util.Locale
import javax.net.ssl.HttpsURLConnection

/** User initiated updates; never reports success before the system installer runs. */
class AppUpdater(private val activity: MainActivity, private val channel: MethodChannel) {
    private var pending: MethodChannel.Result? = null
    private var apk: File? = null
    private val permissionRequest = 7401
    private val installerRequest = 7402

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method == "checkUpdate") {
                checkUpdate(call.argument<String>("manifestUrl") ?: "", call.argument<Boolean>("force") == true, result)
                return@setMethodCallHandler
            }
            if (call.method != "update") { result.notImplemented(); return@setMethodCallHandler }
            if (pending != null) { result.error("busy", "Güncelleme zaten devam ediyor.", null); return@setMethodCallHandler }
            val manifestUrl = call.argument<String>("manifestUrl") ?: ""
            if (manifestUrl.isBlank()) {
                result.error("configuration", "Güncelleme adresi henüz yapılandırılmadı.", null)
                return@setMethodCallHandler
            }
            pending = result
            val labels = call.argument<Map<String, String>>("labels") ?: emptyMap()
            Thread {
                try {
                    val metadata = connection(manifestUrl).let { conn ->
                        try {
                            conn.inputStream.use { input ->
                                val output = ByteArrayOutputStream()
                                val buffer = ByteArray(4096)
                                while (output.size() <= 65536) {
                                    val count = input.read(buffer, 0, minOf(buffer.size, 65537 - output.size()))
                                    if (count < 0) break
                                    output.write(buffer, 0, count)
                                }
                                val bytes = output.toByteArray()
                                require(bytes.size <= 65536) { "Geçersiz sürüm bilgisi." }
                                JSONObject(String(bytes, Charsets.UTF_8))
                            }
                        } finally { conn.disconnect() }
                    }
                    val installed = activity.packageManager.getPackageInfo(activity.packageName, signatureFlags())
                    val remoteVersion = metadata.getLong("versionCode")
                    if (remoteVersion <= versionCode(installed)) {
                        finish("Uygulamanız zaten en son sürüm olan ${installed.versionName} sürümünde.")
                    } else {
                        val hash = metadata.getString("sha256").lowercase()
                        require(hash.matches(Regex("[a-f0-9]{64}"))) { "Geçersiz dosya doğrulama bilgisi." }
                        val address = metadata.getString("apkUrl")
                        val advertisedSize = metadata.optLong("sizeBytes", -1)
                        val size = if (advertisedSize > 0) advertisedSize else connection(address, "HEAD").let { conn ->
                            try { conn.contentLengthLong } finally { conn.disconnect() }
                        }
                        require(size in 1..(700L * 1024 * 1024)) { "İndirme boyutu belirlenemedi. Yeniden dene." }
                        val sizeText = String.format(Locale.US, "%.2f", size / (1024.0 * 1024))
                        if (!confirmDownload(size, sizeText, labels)) {
                            finish(labels["cancelled"] ?: "İndirme iptal edildi.")
                            return@Thread
                        }
                        val directory = File(activity.cacheDir, "updates").apply { mkdirs() }
                        val target = File(directory, "latest.apk")
                        target.delete()
                        val temporary = File(directory, "download.tmp")
                        val downloadLabel = labels["downloading"] ?: "Güncelleme indiriliyor…"
                        status("$downloadLabel · $sizeText MB")
                        try {
                            val conn = connection(address)
                            val digest = MessageDigest.getInstance("SHA-256")
                            try {
                                val length = conn.contentLengthLong
                                require(length <= 700L * 1024 * 1024) { "Güncelleme dosyası çok büyük." }
                                conn.inputStream.use { input ->
                                    temporary.outputStream().use { output ->
                                        val buffer = ByteArray(65536)
                                        var total = 0L
                                        var lastPercent = -1
                                        while (true) {
                                            val count = input.read(buffer)
                                            if (count < 0) break
                                            total += count
                                            require(total <= 700L * 1024 * 1024) { "Güncelleme dosyası çok büyük." }
                                            output.write(buffer, 0, count)
                                            digest.update(buffer, 0, count)
                                            val percent = if (length > 0) (total * 100 / length).toInt() else -1
                                            if (percent != lastPercent) {
                                                lastPercent = percent
                                                status("$downloadLabel %$percent · $sizeText MB")
                                            }
                                        }
                                        require(total == size && (length < 0 || total == length)) { "İndirme tamamlanamadı." }
                                    }
                                }
                            } finally { conn.disconnect() }
                            require(digest.digest().joinToString("") { "%02x".format(it) } == hash) { "İndirilen dosya doğrulanamadı. Yeniden dene." }
                            val archive = activity.packageManager.getPackageArchiveInfo(temporary.path, signatureFlags())
                                ?: error("Geçersiz APK dosyası.")
                            require(archive.packageName == activity.packageName && versionCode(archive) == remoteVersion) { "Güncelleme bu uygulamaya ait değil." }
                            require(signatures(archive) == signatures(installed) && signatures(installed).isNotEmpty()) { "Güncellemenin uygulama imzası eşleşmiyor." }
                            require(temporary.renameTo(target)) { "Güncelleme dosyası hazırlanamadı." }
                            activity.runOnUiThread {
                                apk = target
                                try { installOrRequestPermission() } catch (_: Exception) { fail("Kurulum ekranı açılamadı. Yeniden dene.") }
                            }
                        } finally { temporary.delete() }
                    }
                } catch (e: Exception) {
                    fail(if (e is IllegalArgumentException || e is IllegalStateException) e.message ?: "Güncelleme doğrulanamadı." else "Güncelleme alınamadı. İnternet bağlantını ve boş alanı kontrol edip yeniden dene.")
                }
            }.start()
        }
    }


    private fun checkUpdate(address: String, force: Boolean, reply: MethodChannel.Result) {
        Thread {
            try {
                val installedInfo = activity.packageManager.getPackageInfo(activity.packageName, 0)
        val installed = versionCode(installedInfo)
                val prefs = activity.getSharedPreferences("update-status-v1", Context.MODE_PRIVATE)
                val now = System.currentTimeMillis()
                val cached = prefs.getString("metadata", null)
                val fresh = !force && cached != null && prefs.getString("url", null) == address &&
                    now - prefs.getLong("checkedAt", 0) in 0L..900000L && prefs.getLong("installed", -1) == installed
                val metadata = if (fresh) JSONObject(cached!!) else {
                    val conn = connection(address)
                    try {
                        conn.inputStream.use { input ->
                            val bytes = input.readBytesLimited(65536)
                            JSONObject(String(bytes, Charsets.UTF_8))
                        }
                    } finally { conn.disconnect() }
                }
                val code = metadata.getLong("versionCode")
                val name = metadata.getString("versionName")
                require(code > 0 && name.length in 1..80)
                val notes = metadata.optJSONObject("releaseNotes")
                val translated = listOf("tr", "en", "nl").associateWith { language ->
                    (notes?.optString(language, "") ?: "").take(2000)
                }
                if (!fresh) prefs.edit().putString("metadata", metadata.toString()).putString("url", address)
                    .putLong("checkedAt", now).putLong("installed", installed).apply()
                val value = mapOf("installedVersionName" to installedInfo.versionName,
            "available" to (code > installed), "versionName" to name,
                    "versionCode" to code, "releaseNotes" to translated)
                activity.runOnUiThread { reply.success(value) }
            } catch (_: Exception) {
                activity.runOnUiThread { reply.error("check", "updateCheckError", null) }
            }
        }.start()
    }

    private fun java.io.InputStream.readBytesLimited(limit: Int): ByteArray {
        val out = ByteArrayOutputStream()
        val buffer = ByteArray(4096)
        while (true) {
            val count = read(buffer, 0, minOf(buffer.size, limit + 1 - out.size()))
            if (count < 0) break
            out.write(buffer, 0, count)
            require(out.size() <= limit)
        }
        return out.toByteArray()
    }

    private fun signatureFlags() = if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
    @Suppress("DEPRECATION")
    private fun versionCode(info: PackageInfo): Long = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
    @Suppress("DEPRECATION")
    private fun signatures(info: PackageInfo): Set<String> {
        val certs = if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners else info.signatures
        return certs?.map { cert -> MessageDigest.getInstance("SHA-256").digest(cert.toByteArray()).joinToString("") { "%02x".format(it) } }?.toSet() ?: emptySet()
    }

    private fun confirmDownload(size: Long, sizeText: String, labels: Map<String, String>): Boolean {
        val latch = CountDownLatch(1)
        var accepted = false
        activity.runOnUiThread {
            if (activity.isFinishing || activity.isDestroyed) { latch.countDown(); return@runOnUiThread }
            val manager = activity.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val capabilities = manager.getNetworkCapabilities(manager.activeNetwork)
            val mobile = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) != true
            val key = if (!mobile) "wifi" else if (size <= 2L * 1024 * 1024) "smallMobile" else "largeMobile"
            val fallback = if (mobile) "Dosya boyutu: {size} MB. Mobil veri kullanılacak. Wi-Fi bağlantısı önerilir. İndirmeyi onaylıyor musun?" else "Dosya boyutu: {size} MB. İndirme başlatılsın mı?"
            AlertDialog.Builder(activity)
                .setTitle(labels["title"] ?: "Güncellemeyi indir")
                .setMessage((labels[key] ?: fallback).replace("{size}", sizeText))
                .setPositiveButton(labels["download"] ?: "İndir") { _, _ -> accepted = true; latch.countDown() }
                .setNegativeButton(labels["cancel"] ?: "Vazgeç") { _, _ -> latch.countDown() }
                .setOnCancelListener { latch.countDown() }
                .setOnDismissListener { latch.countDown() }
                .show()
        }
        latch.await()
        return accepted
    }

    private fun connection(address: String, method: String = "GET"): HttpsURLConnection {
        var url = URL(address)
        repeat(6) {
            require(url.protocol == "https") { "Güncelleme bağlantısı HTTPS olmalı." }
            val conn = url.openConnection() as HttpsURLConnection
            conn.connectTimeout = 20000
            conn.readTimeout = 30000
            conn.instanceFollowRedirects = false
            conn.requestMethod = method
            conn.setRequestProperty("User-Agent", "Cevsen-Android")
            conn.setRequestProperty("Cache-Control", "no-cache")
            val code = conn.responseCode
            if (code in listOf(301, 302, 303, 307, 308)) {
                val location = conn.getHeaderField("Location")
                conn.disconnect()
                require(!location.isNullOrBlank()) { "Geçersiz indirme bağlantısı." }
                url = URL(url, location)
            } else {
                if (code != 200) { conn.disconnect(); error("Güncelleme sunucusuna ulaşılamadı ($code). Yeniden dene.") }
                return conn
            }
        }
        error("Güncelleme bağlantısı açılamadı.")
    }

    private fun installOrRequestPermission() {
        if (Build.VERSION.SDK_INT >= 26 && !activity.packageManager.canRequestPackageInstalls()) {
            status("Kurulum için Cevşen uygulamasına izin ver; ardından geri dön.")
            activity.startActivityForResult(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${activity.packageName}")), permissionRequest)
            return
        }
        val file = apk ?: error("Güncelleme dosyası bulunamadı.")
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.apkshare", file)
        status("Güncelleme yükleniyor… Android kurulum onayını bekliyor.")
        activity.startActivityForResult(Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
            data = uri
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            putExtra(Intent.EXTRA_RETURN_RESULT, true)
        }, installerRequest)
    }

    fun onActivityResult(requestCode: Int) {
        if (pending == null) return
        if (requestCode == permissionRequest) {
            if (Build.VERSION.SDK_INT >= 26 && !activity.packageManager.canRequestPackageInstalls()) {
                finish("Kurulum izni verilmedi. Tekrar denemek için Güncelle’ye bas.")
            } else {
                try { installOrRequestPermission() } catch (_: Exception) { fail("Kurulum ekranı açılamadı.") }
            }
        } else if (requestCode == installerRequest) {
            finish("Kurulum ekranı kapatıldı. Sürümü kontrol etmek için Güncelle’ye bas.")
        }
    }

    private fun status(message: String) = activity.runOnUiThread { channel.invokeMethod("status", message) }
    private fun finish(message: String) = activity.runOnUiThread { pending?.success(message); pending = null; apk = null }
    private fun fail(message: String) = activity.runOnUiThread { pending?.error("update", message, null); pending = null; apk = null }
}
