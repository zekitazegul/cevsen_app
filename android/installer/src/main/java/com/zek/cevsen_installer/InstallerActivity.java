package com.zek.cevsen_installer;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import android.widget.TextView;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.MessageDigest;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import org.json.JSONObject;

/** A standalone native bootstrapper. Contains neither Flutter nor the reader APK. */
public final class InstallerActivity extends Activity {
    private static final String APP_ID = "com.zek.cevsen_app";
    private static final int PERMISSION = 8101, INSTALL = 8102;
    private static final long MAX_APK = 250L * 1024 * 1024;
    private TextView status;
    private ProgressBar progress;
    private Button primary, cancel;
    private boolean busy, ready, installedReady;
    private long expectedVersion;
    private volatile boolean cancelled;
    private volatile HttpURLConnection activeConnection;

    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        getWindow().setStatusBarColor(Color.rgb(250, 245, 233));
        getWindow().setNavigationBarColor(Color.rgb(250, 245, 233));
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR | View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR);
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setBackgroundColor(Color.rgb(250, 245, 233));
        LinearLayout body = new LinearLayout(this);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setPadding(dp(24), dp(40), dp(24), dp(32));
        // Keep content clear of system bars on edge-to-edge Android versions.
        body.setOnApplyWindowInsetsListener((v, insets) -> {
            v.setPadding(dp(24) + insets.getSystemWindowInsetLeft(), dp(32) + insets.getSystemWindowInsetTop(),
                dp(24) + insets.getSystemWindowInsetRight(), dp(24) + insets.getSystemWindowInsetBottom());
            return insets;
        });
        TextView title = text("Cevsen Installer", 28);
        body.addView(title);
        TextView intro = text("Cevşen’in güncel sürümünü internetten indirip kolayca kurabilirsin.\n\nSes kayıtlarını Cevşen içinde dinlemek istediğinde ayrıca indirebilirsin. Wi-Fi bağlantısı önerilir.", 17);
        intro.setPadding(0, dp(20), 0, dp(24));
        body.addView(intro);
        status = text("Başlamak için İndir ve kur’a dokun.", 16);
        body.addView(status);
        progress = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
        progress.setMax(100);
        progress.setVisibility(View.GONE);
        body.addView(progress, new LinearLayout.LayoutParams(-1, dp(24)));
        primary = new Button(this);
        primary.setText("İndir ve kur");
        primary.setAllCaps(false);
        primary.setOnClickListener(v -> {
            if (installedReady) openReader();
            else if (ready) install();
            else download();
        });
        body.addView(primary);
        cancel = new Button(this);
        cancel.setText("Vazgeç");
        cancel.setAllCaps(false);
        cancel.setVisibility(View.GONE);
        cancel.setOnClickListener(v -> cancelDownload());
        body.addView(cancel);
        TextView privacy = text("İndirme GitHub üzerinden yapılır. İnternet veya mobil veri kullanılır. Kurulum için Android’in izin ve onay ekranları açılır.", 13);
        privacy.setPadding(0, dp(20), 0, 0);
        body.addView(privacy);
        scroll.addView(body);
        setContentView(scroll);
        if (saved != null && saved.getBoolean("ready")) {
            expectedVersion = saved.getLong("version");
            try {
                verifyApk(target(), expectedVersion);
                ready = true;
                status.setText("Dosya hazır. Kuruluma devam edebilirsin.");
                primary.setText("Kuruluma devam et");
            } catch (Exception ignored) { ready = false; }
        }
    }

    private int dp(int value) { return Math.round(value * getResources().getDisplayMetrics().density); }
    private TextView text(String value, int size) {
        TextView view = new TextView(this);
        view.setText(value);
        view.setTextSize(size);
        view.setTextColor(Color.rgb(18, 63, 53));
        return view;
    }
    private File target() { return new File(getCacheDir(), "Cevsen.apk"); }
    private void ui(Runnable action) {
        runOnUiThread(() -> { if (!isFinishing() && !isDestroyed()) action.run(); });
    }
    private void message(String value) { ui(() -> status.setText(value)); }
    private void setBusy(boolean value) {
        busy = value;
        primary.setEnabled(!value);
        cancel.setVisibility(value ? View.VISIBLE : View.GONE);
        progress.setVisibility(value ? View.VISIBLE : View.GONE);
        if (value) getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        else getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }
    private void cancelDownload() {
        cancelled = true;
        cancel.setEnabled(false);
        status.setText("İndirme iptal ediliyor…");
        HttpURLConnection connection = activeConnection;
        if (connection != null) new Thread(connection::disconnect).start();
    }

    private void download() {
        if (busy) return;
        cancelled = false;
        cancel.setEnabled(true);
        progress.setProgress(0);
        progress.setIndeterminate(true);
        setBusy(true);
        status.setText("Güncel sürüm kontrol ediliyor…");
        new Thread(() -> {
            File partial = new File(getCacheDir(), "download.part");
            try {
                JSONObject metadata;
                HttpURLConnection connection = connection(BuildConfig.MANIFEST_URL);
                try (InputStream input = connection.getInputStream(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
                    byte[] buffer = new byte[4096];
                    int count;
                    while ((count = input.read(buffer)) != -1) {
                        checkCancelled();
                        if (output.size() + count > 65536) throw new IllegalArgumentException("Geçersiz sürüm bilgisi.");
                        output.write(buffer, 0, count);
                    }
                    metadata = new JSONObject(output.toString("UTF-8"));
                } finally { connection.disconnect(); }
                expectedVersion = metadata.getLong("versionCode");
                long size = metadata.getLong("sizeBytes");
                String hash = metadata.getString("sha256").toLowerCase(Locale.ROOT);
                if (expectedVersion < 1 || size < 1 || size > MAX_APK || !hash.matches("[a-f0-9]{64}")) {
                    throw new IllegalArgumentException("Geçersiz indirme bilgisi.");
                }
                if (installedVersion() >= expectedVersion) {
                    ui(() -> {
                        installedReady = true;
                        primary.setText("Cevşen’i aç");
                        status.setText("Cevşen’in güncel sürümü zaten yüklü.");
                    });
                    return;
                }
                File apk = target();
                checkCancelled();
                if (!(apk.isFile() && apk.length() == size && hash.equals(hash(apk)))) {
                    connection = connection(metadata.getString("apkUrl"));
                    try (InputStream input = connection.getInputStream(); FileOutputStream output = new FileOutputStream(partial)) {
                        byte[] buffer = new byte[65536];
                        int count, lastPercent = -1;
                        long received = 0;
                        MessageDigest digest = MessageDigest.getInstance("SHA-256");
                        while ((count = input.read(buffer)) != -1) {
                            checkCancelled();
                            received += count;
                            if (received > size) throw new IllegalArgumentException("İndirme boyutu doğrulanamadı.");
                            output.write(buffer, 0, count);
                            digest.update(buffer, 0, count);
                            int percent = (int) (received * 100 / size);
                            if (percent != lastPercent) {
                                lastPercent = percent;
                                ui(() -> {
                                    progress.setIndeterminate(false);
                                    progress.setProgress(percent);
                                    status.setText(String.format(Locale.getDefault(), "Cevşen indiriliyor… %%%d · %.1f MB", percent, size / 1000000.0));
                                });
                            }
                        }
                        if (received != size || !hash.equals(hex(digest.digest()))) throw new IllegalArgumentException("İndirilen dosya doğrulanamadı. Yeniden dene.");
                    } finally { connection.disconnect(); }
                    checkCancelled();
                    verifyApk(partial, expectedVersion);
                    if (apk.exists() && !apk.delete()) throw new IllegalStateException("Eski indirme silinemedi.");
                    if (!partial.renameTo(apk)) throw new IllegalStateException("Kurulum dosyası hazırlanamadı.");
                }
                verifyApk(apk, expectedVersion);
                checkCancelled();
                ui(() -> {
                    ready = true;
                    primary.setText("Kuruluma devam et");
                    install();
                });
            } catch (Exception error) {
                message(cancelled ? "İndirme iptal edildi. Tekrar başlatabilirsin." :
                    error instanceof IllegalArgumentException ? error.getMessage() :
                    "İndirme tamamlanamadı. İnternet bağlantını ve boş alanı kontrol edip yeniden dene.");
            } finally {
                partial.delete();
                activeConnection = null;
                ui(() -> setBusy(false));
            }
        }, "cevsen-download").start();
    }

    private void checkCancelled() throws InterruptedException {
        if (cancelled) throw new InterruptedException();
    }
    private HttpURLConnection connection(String address) throws Exception {
        URL url = new URL(address);
        for (int redirect = 0; redirect < 6; redirect++) {
            checkCancelled();
            boolean localTest = BuildConfig.DEBUG && "http".equals(url.getProtocol()) && "127.0.0.1".equals(url.getHost());
            if (!"https".equals(url.getProtocol()) && !localTest) throw new IllegalArgumentException("İndirme bağlantısı güvenli değil.");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            activeConnection = conn;
            conn.setConnectTimeout(20000);
            conn.setReadTimeout(30000);
            conn.setInstanceFollowRedirects(false);
            conn.setRequestProperty("User-Agent", "Cevsen-Installer");
            conn.setRequestProperty("Cache-Control", "no-cache");
            int code;
            try { code = conn.getResponseCode(); }
            catch (Exception e) { conn.disconnect(); throw e; }
            if (code == 301 || code == 302 || code == 303 || code == 307 || code == 308) {
                String location = conn.getHeaderField("Location");
                conn.disconnect();
                if (location == null) throw new IllegalArgumentException("Geçersiz indirme bağlantısı.");
                url = new URL(url, location);
            } else {
                if (code != 200) { conn.disconnect(); throw new IllegalStateException("İndirme sunucusuna ulaşılamadı."); }
                return conn;
            }
        }
        throw new IllegalArgumentException("İndirme bağlantısı açılamadı.");
    }
    @SuppressWarnings("deprecation")
    private int signatureFlags() { return Build.VERSION.SDK_INT >= 28 ? PackageManager.GET_SIGNING_CERTIFICATES : PackageManager.GET_SIGNATURES; }
    @SuppressWarnings("deprecation")
    private long version(PackageInfo info) { return Build.VERSION.SDK_INT >= 28 ? info.getLongVersionCode() : info.versionCode; }
    private long installedVersion() {
        try { return version(getPackageManager().getPackageInfo(APP_ID, 0)); }
        catch (PackageManager.NameNotFoundException e) { return 0; }
    }
    @SuppressWarnings("deprecation")
    private Set<String> signatures(PackageInfo info) throws Exception {
        Signature[] certs = Build.VERSION.SDK_INT >= 28 ? (info.signingInfo == null ? null : info.signingInfo.getApkContentsSigners()) : info.signatures;
        Set<String> result = new HashSet<>();
        if (certs != null) for (Signature cert : certs) result.add(hex(MessageDigest.getInstance("SHA-256").digest(cert.toByteArray())));
        return result;
    }
    private void verifyApk(File apk, long expected) throws Exception {
        PackageInfo archive = getPackageManager().getPackageArchiveInfo(apk.getPath(), signatureFlags());
        if (archive == null || !APP_ID.equals(archive.packageName) || version(archive) != expected) {
            throw new IllegalArgumentException("Kurulum dosyası doğrulanamadı. Yeniden dene.");
        }
        Set<String> trusted = signatures(getPackageManager().getPackageInfo(getPackageName(), signatureFlags()));
        if (trusted.isEmpty() || !trusted.equals(signatures(archive))) throw new IllegalArgumentException("Uygulama imzası doğrulanamadı.");
    }
    private String hash(File file) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        try (InputStream input = new FileInputStream(file)) {
            byte[] buffer = new byte[65536]; int count;
            while ((count = input.read(buffer)) != -1) { checkCancelled(); digest.update(buffer, 0, count); }
        }
        return hex(digest.digest());
    }
    private static String hex(byte[] bytes) {
        StringBuilder result = new StringBuilder();
        for (byte b : bytes) result.append(String.format(Locale.ROOT, "%02x", b & 255));
        return result.toString();
    }
    @SuppressWarnings("deprecation")
    private void install() {
        try {
            if (!ready) return;
            if (Build.VERSION.SDK_INT >= 26 && !getPackageManager().canRequestPackageInstalls()) {
                status.setText("Cevsen Installer için uygulama yükleme iznini açıp geri dön.");
                startActivityForResult(new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:" + getPackageName())), PERMISSION);
                return;
            }
            verifyApk(target(), expectedVersion);
            Intent intent = new Intent(Intent.ACTION_INSTALL_PACKAGE);
            intent.setData(Uri.parse("content://" + getPackageName() + ".apk/Cevsen.apk"));
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            intent.putExtra(Intent.EXTRA_RETURN_RESULT, true);
            status.setText("Android kurulum onayını bekliyor…");
            startActivityForResult(intent, INSTALL);
        } catch (Exception e) { status.setText("Kurulum ekranı açılamadı. Yeniden dene."); }
    }
    @Override protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request == PERMISSION) {
            if (Build.VERSION.SDK_INT < 26 || getPackageManager().canRequestPackageInstalls()) install();
            else status.setText("Kurulum izni verilmedi. Kuruluma devam et’e dokunarak yeniden deneyebilirsin.");
        } else if (request == INSTALL) {
            if (installedVersion() >= expectedVersion) {
                installedReady = true;
                primary.setText("Cevşen’i aç");
                status.setText("Cevşen yüklendi. Cevsen Installer’ı daha sonra telefonunun uygulama ayarlarından kaldırabilirsin.");
                target().delete();
                ready = false;
            } else status.setText("Kurulum tamamlanmadı. İndirmeden tekrar deneyebilirsin.");
        }
    }
    private void openReader() {
        Intent launch = getPackageManager().getLaunchIntentForPackage(APP_ID);
        if (launch != null) startActivity(launch);
        else { installedReady = false; primary.setText("İndir ve kur"); status.setText("Cevşen bulunamadı. Yeniden kurabilirsin."); }
    }
    @Override protected void onSaveInstanceState(Bundle state) {
        state.putBoolean("ready", ready);
        state.putLong("version", expectedVersion);
        super.onSaveInstanceState(state);
    }
    @Override public void onBackPressed() {
        if (busy) cancelDownload(); else super.onBackPressed();
    }
    @Override protected void onDestroy() {
        cancelled = true;
        HttpURLConnection connection = activeConnection;
        if (connection != null) new Thread(connection::disconnect).start();
        super.onDestroy();
    }
}
