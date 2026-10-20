# Cevşen

Flutter ile hazırlanmış, çevrimdışı çalışan bağımsız Android okuma uygulaması.

- 100 bab; harekeli Arapça metin ve Latin harfli Türkçe **okunuş**.
- İçindekiler listesinden doğrudan bab seçimi; kaldığı babı hatırlama.
- Sıkıştırılmış içindekiler: her satırda yalnızca bab adı, önizleme veya ikinci sıra numarası yok.
- Tam genişlikte, dikey kaydırılabilen okuma; çift dokunarak tam ekran açma/kapatma.
- Arapça ve Türkçe okunuş için ayrı ekranlar; üst çubukta dinleme denetimi, sabit alt ses kartı yok.
- Her sayfada bir bab; okunabilir alt sınıra kadar ekrana sığdırma, uzun veya büyütülmüş bablarda dikey kaydırma.
- Arapça ve Türkçe için ayrı, kalıcı yazı boyutları.
- Üst çubukta kalıcı Arapça düzen tercihi: “Ortala” ve yıldızla birlikte her cümlenin sağdan yeni satırda başladığı “Sağdan başla” ikonları.
- Türkçe okunuşta “Ortala” ve “Sola dayalı” ikonları; tercihler Arapçadan bağımsız kaydedilir.
- Parmağı birebir takip eden, bırakıldığında mesafeye ve hıza göre yerine oturan bab sayfaları.
- Enes Sakallı'nın 100 babın tamamını kapsayan on ses kaydı; seçili baba göre yerel ses kesiti, duraklatma ve zaman çubuğu.
- Zümrüt/altın geometrik motifler; düzenlenebilir SVG ve 1024 px PNG logo.
- Belirgin sayfa kenarları: koyu dış zemin, krem kâğıt yüzeyi, ince çerçeve ve hafif gölge.

## Çalıştırma

```sh
flutter pub get
flutter test
flutter run
flutter build apk --release
```

Uygulama kimliği: `com.zek.cevsen_app`. KuranApp'tan bağımsız kurulur.

## Paylaşım ve güncelleme

Ayarlar’dan kurulu APK paylaşılır. Güncelle düğmesi `zekitazegul/cevsen_app` deposunun son sürümündeki `update.json` dosyasını kontrol eder, yeni sürümü uygulama içinde indirir ve Android kurulum onayını açar. Sürüm karşılaştırması `versionCode` ile yapılır; ekranda cihazda kurulu sürüm gösterilir. İnternet hatası güncel sürüm sonucu olarak gösterilmez.

Yeni sürüm için `pubspec.yaml` sürümünü ve build numarasını artır, `appVersion` değerini ve değişiklik notlarını güncelle; `flutter analyze`, `flutter test`, `flutter build apk --release` çalıştır. Aynı Android imzalama anahtarını koru. Ardından `powershell -File tools/publish_release.ps1` APK ve SHA-256 içeren `update.json` dosyasını aynı GitHub sürümüne yükler. Kullanıcı GitHub sayfası görmez. Kaynak adresi gerekirse `--dart-define=UPDATE_MANIFEST_URL=https://.../update.json` ile değiştirilebilir.

## Kaynaklar

Metinler: https://nurulkuran.com/cevsen/1 … /100. Sadece `lang="ar"` ve Latin harfli `lang="tr"` okunuş satırları alınmıştır; meal alınmaz. Kaynağın bablara göre değişen hallisnâ / ecirnâ / neccinâ kapanışları korunur. 73. bab kaynağında dokuz nida ve kapanış bulunur; eksik olduğu varsayılarak yeni satır üretilmemiştir.

Ses: https://herkul.org/cevsen/1~10 … /91~100; seslendiren Enes Sakallı. Asıl MP3 adresleri `assets/audio/index.json` içinde saklanır. Dosyalar uygulamaya dahildir; internet gerekmez. `chapters.json` her babın aynı dosya içindeki başlangıç/bitişini belirtir. Sınırlar, tekrarlanan kapanış duasının akustik eşleştirmesi ve sessiz duraklardan çıkarılmıştır; 100 sınırın tamamı insan tarafından dinlenerek onaylanmış değildir.

Yazı tipi: Amiri, SIL Open Font License; lisans `assets/fonts/OFL.txt`.

Logo: `assets/branding/cevsen-logo.svg` ve `.png`. Android ve web simgeleri `tools/make_logo.py` ile üretilir.

## İçerik araçları

Ham sayfalar `assets/raw/1.html` … `100.html` olarak indirildikten sonra `python tools/download_content.py` eşlenmiş metinleri oluşturur. Ses kaynak sayfaları `assets/raw/audio-1.html` … `audio-91.html` olarak kaydedilip `python tools/prepare_audio.py` çalıştırılır. Araçların ihtiyaç duyduğu ham sayfalar ve yerel Python bağımlılıkları dağıtım paketine dahil edilmez.

`tools/audio_boundaries.py`, `match_audio.py`, `align_refrains.py`, `build_audio_index.py` sırasıyla durakları, akustik özellikleri ve kesit dizinini üretir. Ses analizi için `imageio-ffmpeg` ve `numpy`; logo çıktıları için Pillow gerekir. Kod `tools/vendor` altındaki yerel bağımlılıkları kullanabilir. Uygulamanın çalışması Python gerektirmez.

Testler, 100 babın Arapça/okunuş eşlerini, ses kesitlerinin kaynak dosyaları kesintisiz kapsamasını, farklı ekranlarda doğrudan bab seçimini, metinlerin ayrılmasını, ekrana sığdırmayı ve parmağı takip eden sayfa geçişini kontrol eder.
