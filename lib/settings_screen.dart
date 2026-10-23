import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_update.dart';
import 'screen_awake.dart';

const supportUrl = 'https://zekitazegul.github.io/support/?lang=tr';
const tikkieUrl = 'https://tikkie.me/pay/qp5ddh9l8i6gg1dq6bc0';
const appVersion = '1.2.7';

Future<void> openExternal(BuildContext context, String url) async {
  try {
    await const MethodChannel('com.zek.cevsen_app/external')
        .invokeMethod<void>('openUrl', {'url': url});
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bağlantı kopyalandı. Tarayıcında açabilirsin.'),
        ),
      );
    }
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.prefs});
  final SharedPreferences prefs;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double ar, tr, meal;
  late bool fit, right, left, effect, keepScreenOn;
  bool preparingInstaller = false;

  Future<void> shareInstaller() async {
    if (preparingInstaller) return;
    setState(() => preparingInstaller = true);
    try {
      await const MethodChannel('com.zek.cevsen_app/external')
          .invokeMethod<void>('shareInstaller');
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Kurulum dosyası paylaşılamadı.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kurulum dosyası paylaşılamadı. Yeniden dene.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => preparingInstaller = false);
    }
  }

  @override
  void initState() {
    super.initState();
    keepScreenOn = widget.prefs.getBool('keepScreenOn') ?? true;
    ar = widget.prefs.getDouble('arSize') ?? 32;
    tr = widget.prefs.getDouble('trSize') ?? 20;
    meal = widget.prefs.getDouble('mealSize') ?? 18;
    fit = widget.prefs.getBool('fitPage') ?? true;
    effect = widget.prefs.getBool('pageEffect') ?? true;
    right = widget.prefs.getBool('arabicLineStarts') ?? true;
    left = widget.prefs.getBool('transcriptLeftAligned') ?? false;
  }

  void document(String title, List<Widget> content) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => DocumentScreen(title: title, content: content),
    ),
  );
  Widget sizeControl(
    String name,
    double value,
    double min,
    double max,
    String key,
    void Function(double) update,
  ) => Column(
    children: [
      Text('$name · ${value.round()}'),
      Slider(
        min: min,
        max: max,
        value: value,
        onChanged: (v) {
          setState(() {
            update(v);
            fit = false;
          });
          widget.prefs.setDouble(key, v);
          widget.prefs.setBool('fitPage', false);
        },
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ayarlar')),
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        12 + MediaQuery.viewPaddingOf(context).left,
        8,
        12 + MediaQuery.viewPaddingOf(context).right,
        12 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Card(
          child: ExpansionTile(
            initiallyExpanded: false,
            leading: const Icon(Icons.auto_stories_outlined),
            title: const Text('Okuma ve görünüm'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sayfa çevirme efekti'),
                subtitle: const Text(
                  'Kapalıyken kaydırma doğrudan sonraki sayfaya geçer.',
                ),
                value: effect,
                onChanged: (v) {
                  setState(() => effect = v);
                  widget.prefs.setBool('pageEffect', v);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sayfayı ekrana sığdır'),
                subtitle: const Text(
                  'Uzun ve büyütülmüş metinler aşağı kaydırılır.',
                ),
                value: fit,
                onChanged: (v) {
                  setState(() => fit = v);
                  widget.prefs.setBool('fitPage', v);
                },
              ),
              sizeControl(
                'Arapça yazı boyutu',
                ar,
                22,
                128,
                'arSize',
                (v) => ar = v,
              ),
              sizeControl(
                'Türkçe okunuş yazı boyutu',
                tr,
                14,
                128,
                'trSize',
                (v) => tr = v,
              ),
              sizeControl(
                'Meal yazı boyutu',
                meal,
                14,
                128,
                'mealSize',
                (v) => meal = v,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Arapça: sağdan başla'),
                subtitle: const Text(
                  'Kapalıyken ortalanmış akıcı düzen kullanılır.',
                ),
                value: right,
                onChanged: (v) {
                  setState(() => right = v);
                  widget.prefs.setBool('arabicLineStarts', v);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Türkçe okunuş: sola dayalı'),
                value: left,
                onChanged: (v) {
                  setState(() => left = v);
                  widget.prefs.setBool('transcriptLeftAligned', v);
                },
              ),
            ],
          ),
        ),
        const AppUpdateTile(),
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.screen_lock_portrait_outlined),
            title: const Text('Ekranı açık tut'),
            children: [
              SwitchListTile(
                title: const Text('Uygulama açıkken'),
                subtitle: const Text('Ekran otomatik kapanmaz.'),
                value: keepScreenOn,
                onChanged: (value) async {
                  try {
                    await setScreenAwake(value);
                    await widget.prefs.setBool('keepScreenOn', value);
                    if (mounted) setState(() => keepScreenOn = value);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ekran ayarı değiştirilemedi. Yeniden dene.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.share_outlined),
            title: const Text('Uygulamayı paylaş'),
            children: [
              ListTile(
                title: Text(
                  preparingInstaller
                      ? 'Kurulum dosyası hazırlanıyor…'
                      : 'Cevsen Installer’ı paylaş',
                ),
                subtitle: const Text(
                  'Küçük kurulum dosyasını WhatsApp veya e-postayla gönder. Cevşen alıcının telefonuna internetten indirilir; sesler isteğe bağlıdır.',
                ),
                trailing: preparingInstaller
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.android),
                onTap: preparingInstaller ? null : shareInstaller,
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              ExpansionTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Uygulama hakkında'),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cevşen',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const Text('Sürüm $appVersion'),
                  const SizedBox(height: 16),
                  const Text(
                    'Cevşen-i Kebîr’in 100 babını ve kapanış duasını Arapça, meal ve Türkçe okunuş ile okuyabilirsin. Okunuş, Latin harfli telaffuzdur; meal anlamı gösterir. Metinler cihazda bulunur. Sesler ilk dinleme isteğinde indirilir; ardından çevrimdışı dinlenebilir.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Uygulama ücretsiz ve reklamsızdır. Üyelik veya abonelik gerekmez. Kahve ikramı tamamen isteğe bağlıdır; hiçbir okuma özelliği ödeme gerektirmez.',
                  ),
                ],
              ),
              ExpansionTile(
                leading: const Icon(Icons.copyright_outlined),
                title: const Text('Kaynaklar ve telif bilgileri'),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cevşen metinleri',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '100 babın Arapça metni ve Türkçe okunuşu: Nurul Kuran. Kapanış duasının Arapça metni: Nukteler; okunuş karşılaştırması: Muhammed.net. Meal, dua metninin Türkçe anlamını sunar.',
                  ),
                  const SelectableText(
                    'https://nurulkuran.com/cevsen\nhttps://www.nukteler.com/cevsen-hatim-duasi/\nhttps://www.muhammed.net/2023/01/cevsen-ul-kebir-duasi-okunusu-fazileti.html',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ses kayıtları',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Ses kayıtları Herkul Cevşen arşivinden alınmıştır. Kaynak içeriklerin hakları ilgili hak sahiplerine aittir. Bu uygulama kaynak yayıncıların resmî uygulaması değildir. Kaynak belirtmek, ayrıca bir yeniden kullanım lisansı verildiği anlamına gelmez.',
                  ),
                  const SelectableText('https://herkul.org/cevsen'),
                  const SizedBox(height: 16),
                  const Text(
                    'Amiri yazı tipi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Amiri, SIL Open Font License 1.1 ile kullanılır. Tam lisans metni Lisanslar bölümündedir. Uygulama simgesi ve sayfa tasarımı bu proje için hazırlanmıştır.',
                  ),
                  const SizedBox(height: 16),
                  const Text('Telif veya içerik düzeltme talepleri'),
                  const Text(
                    'Destek ve iletişim bölümünden mesaj gönderebilirsin.',
                  ),
                ],
              ),
              ExpansionTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Lisanslar'),
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Tüm lisansları görüntüle'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Cevşen',
                      applicationVersion: appVersion,
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Gizlilik ve erişimler'),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Son okunan bölüm, yazı boyutları ve görünüm tercihleri cihazının uygulamaya ait depolamasında saklanır. Hesap, reklam veya analiz SDK’sı bulunmaz. Android bulut yedeklemesi kapalıdır.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Okuma çevrimdışı çalışır. Dinleme için tüm ses kayıtları bir kez Herkul sunucusundan indirilir; ardından internet gerekmez. Sunucu IP adresi gibi bağlantı bilgilerini görebilir. Ayarlar açıldığında yeni sürüm bilgisi GitHub üzerinden kontrol edilir. Güncelle seçildiğinde varsa yeni APK indirilir; GitHub IP adresi gibi bağlantı bilgilerini görebilir. Mobil veri ücreti oluşabilir. Paylaşımda yalnızca küçük kurucu gönderilir; alıcı uygulamayı internetten indirir. Kurulum Android onayıyla tamamlanır. Destek veya kaynak bağlantısını seçersen haricî tarayıcı açılır. Tarayıcı, destek sitesi ve ödeme sağlayıcısının kendi koşulları geçerlidir. Uygulama banka veya kart bilgilerini işlemez.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kamera, mikrofon, konum veya rehber izni istenmez. Yerel tercihleri silmek için Android ayarlarından uygulama verilerini temizleyebilir veya uygulamayı kaldırabilirsin.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gizlilik soruların için Destek ve iletişim bölümünü kullanabilirsin.',
                  ),
                ],
              ),
              ExpansionTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Kullanım kılavuzu'),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İçindekilerden bir bab veya kapanış duası seç. Arapça, Meal ve Türkçe okunuş sekmeleri aynı bölümü gösterir. Yatay sürüklemede sayfa parmağını takip eder; uzun metinler aşağı kaydırılabilir.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Çift dokunarak tam ekranı açıp kapat. A− ve A+ etkin sekmenin yazısını değiştirir. Hizalama ikonları Arapçada Ortala / Sağdan başla, Türkçede Ortala / Sola dayalı seçeneklerini uygular. Kulaklık simgesi dinlemeyi başlatır; tekrar dokunarak duraklatabilirsin.',
                  ),
                ],
              ),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.local_cafe_outlined),
            title: const Text('Destek ve iletişim'),
            children: const [SupportCard()],
          ),
        ),
      ],
    ),
  );
}

class DocumentScreen extends StatelessWidget {
  const DocumentScreen({super.key, required this.title, required this.content});
  final String title;
  final List<Widget> content;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(24), children: content),
  );
}

class SupportCard extends StatelessWidget {
  const SupportCard({super.key});
  Future<void> open(BuildContext context, String url) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Birlikte güzelleştirelim'),
        content: const Text(
          'Destek sayfası tarayıcıda açılacak. Kahve ikramı tamamen isteğe bağlıdır; uygulamadaki tüm özellikler ücretsiz kalır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Devam et'),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) await openExternal(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final current = DateTime.now().toUtc().isBefore(
      DateTime.utc(2026, 10, 27, 23),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.local_cafe_outlined),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bir kahveyle destek ol',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Dilersen bir fikir, teşekkür veya kahve ikramıyla uygulamanın geliştirilmesine katkıda bulunabilirsin. Destek tamamen isteğe bağlıdır.',
            ),
            const SizedBox(height: 12),
            if (current)
              FilledButton.icon(
                onPressed: () => open(context, tikkieUrl),
                icon: const Icon(Icons.local_cafe_outlined),
                label: const Text('Tikkie ile kahve ikram et'),
              ),
            if (current)
              const Text(
                'Mevcut Tikkie bağlantısı 27 Ekim 2026’ya kadar geçerlidir.',
                style: TextStyle(fontSize: 12),
              ),
            OutlinedButton.icon(
              onPressed: () => open(context, supportUrl),
              icon: const Icon(Icons.favorite_outline),
              label: Text(
                current
                    ? 'Destek ve geri bildirim'
                    : 'Güncel destek bağlantısı ve geri bildirim',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
