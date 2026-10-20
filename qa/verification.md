# Doğrulama — 20 Ekim 2026

- `flutter analyze`: sorun yok.
- `flutter test`: 5 test geçti. 100 metin çifti ve kapanışları; 100 ses kesitinin on kaynak kaydı kesintisiz kapsaması; 360×640, 800×360, 1024×1366 boyutlarında bab arama.
- Android debug APK başarıyla derlendi ve bağlı Galaxy telefona Wi-Fi üzerinden kuruldu.
- Telefon: 1080×2340. Ana ekran ve logo, Arapça Amiri yazı tipi ve Türkçe okunuş görsel olarak kontrol edildi.
- Arapça boyutu 32→40, Türkçe boyutu 20→24 değiştirildi; ayar ekranı ve uygulamanın SharedPreferences dosyasında kalıcılık doğrulandı.
- Yatay sürükleme bırakılınca 1→2. bab geçişi, tam ekran ve dikey metin kaydırma doğrulandı.
- 1. ve 2. bab için Android AudioPlaybackConfiguration `state:started` kaydı gözlendi; oynatma denemeleri durduruldu.
- Tüm 100 babın ses başlangıçları tek tek insan tarafından dinlenerek doğrulanmadı. Akustik eşleştirme ve sessiz duraklarla oluşturulan işaretler `assets/audio/chapters.json` içinde.

Görüntüler: `home.png`, `reader.png`, `settings.png`, `fullscreen.png`.

## 1.0.2+3

- 13 test geçti; statik analizde sorun bulunmadı.
- Parmağı kaldırmadan yapılan kısmi yatay sürüklemede `PageController.page` değerinin 0 ile 1 arasında olduğu test edildi; bırakınca ikinci baba geçtiği doğrulandı.
- Türkçe görünümde Arapça karakter olmadığı, sabit ses kartı/oynat simgesi/seslendiren adı bulunmadığı test edildi.
- Kısa babın tek ekrana sığdığı ve büyütülmüş metnin kaydırılabildiği test edildi.
- İçindekilerde giriş alanı, ikinci sayı ve okunuş önizlemesi olmadığı; 100. baba küçük telefon/yatay ekran/tablet düzenlerinde kaydırarak erişilebildiği test edildi.
- Telefon görüntüleri: `compact-library.png`, `separate-reader.png`. 29. bab Türkçe okunuş ekranında bir bütün olarak görüntülendi; alt ses kartı yok.

## 1.0.3+4

- Giriş ekranının logo, tanıtım yazıları ve “BABLAR / 100 bab” başlığı kaldırıldı.
- Okuma ekranında çift dokunarak tam ekran açma/kapatma testi geçti; üst/alt tam ekran simgelerinin bulunmadığı doğrulandı.
- Sürükleme testi, hareketin başlangıcındaki dokunma eşiğini aşan ardışık hareketlerle sayfanın parmağı izlediğini doğrular.
- İçindekiler için mevcut 5 test geçti; çift dokunma eklenmiş okuma testi geçti.

## 1.0.5+6

- 13 test geçti; Android derlemesi ve telefona kurulum tamamlandı.
- `arabic-lines.png`: yıldızlar sağda, her Arapça cümle ayrı ve sağa hizalı satırda.
- Ayarlarda “Arapça sayfa düzeni” seçimi görüntülendi; akıcı düzen de cihazda görüntülendi.
- Tercih `arabicLineStarts` anahtarıyla SharedPreferences içinde saklanır.

## 1.0.6+8

- 13 test geçti; sürüm telefona kuruldu.
- Arapçada üstte “Ortala” / “Sağdan başla”, Türkçe okunuşta “Ortala” / “Sola dayalı” ikonları doğrulandı.
- Türkçe üst çubukta bab adı bulunmadığı cihazın arayüz ağacında doğrulandı.
- `arabicLineStarts` ve `transcriptLeftAligned` tercihlerinin ayrı kaydedildiği kontrol edildi.
- Görsel kontrol: `turkish-left.png`; Türkçe cümleler sol kenardan başlar.


## 1.1.0+9

- 13 mevcut test ve yeni aşağı kaydırma işareti testi geçti; statik analiz temiz.
- Android APK derlendi ve telefonda versionName=1.1.0 / versionCode=9 doğrulandı.
- Telefonda büyük sistem yazısında sekme adlarının bölündüğü görüldü; sekmeler tek satırda alana sığacak biçimde düzeltildi, okuyucu testi yeniden geçti.
- Son satıra kaydırıldığında devam işaretinin kaybolması widget testiyle doğrulandı.

## 1.1.4+13

- “Tüm lisansları görüntüle” ve “Destek ve iletişim” yazılarındaki soru işareti karakterleri düzeltildi.
- Cevşen ve KuranApp kaynakları dahil 68 kaynak/içerik dosyası UTF-8, bozuk karakter dizileri ve kelime içindeki soru işaretleri için tarandı; başka bozuk metin bulunmadı.
- Statik analiz temiz.
- 1.1.4 telefona kuruldu; lisans düğmesi ve destek başlığı arayüz ağacında doğru Türkçe karakterlerle doğrulandı.
- GitHub deposu `zekitazegul/cevsen_app` olarak yeniden adlandırıldı; eski güncelleme adresi HTTP 200 yanıtıyla çalışmaya devam ediyor.
