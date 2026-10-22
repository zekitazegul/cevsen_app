import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const updateManifestUrl = String.fromEnvironment(
  'UPDATE_MANIFEST_URL',
  defaultValue: 'https://github.com/zekitazegul/cevsen_app/releases/latest/download/update.json',
);

class AppUpdateTile extends StatefulWidget {
  const AppUpdateTile({super.key});

  @override
  State<AppUpdateTile> createState() => _AppUpdateTileState();
}

class _AppUpdateTileState extends State<AppUpdateTile> {
  static const channel = MethodChannel('com.zek.cevsen_app/update');
  bool busy = false;
  String status =
      'Güncellemeyi indirmek internet verisi kullanır. Wi-Fi bağlantısı önerilir.';

  @override
  void initState() {
    super.initState();
    channel.setMethodCallHandler((call) async {
      if (mounted && call.method == 'status') {
        setState(() => status = call.arguments as String);
      }
    });
  }

  @override
  void dispose() {
    channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> check() async {
    if (busy) return;
    setState(() {
      busy = true;
      status = 'Son güncellemeler kontrol ediliyor…';
    });
    try {
      final message = await channel.invokeMethod<String>('update', {
        'manifestUrl': updateManifestUrl,
        'labels': {
          'title': 'Güncellemeyi indir',
          'wifi': 'Dosya boyutu: {size} MB. İndirme başlatılsın mı?',
          'smallMobile': 'Dosya boyutu: {size} MB (2 MB veya daha az). Mobil veriyle indirmeyi onaylıyor musun?',
          'largeMobile': 'Dosya boyutu: {size} MB. Wi-Fi bağlantısı önerilir. Mobil veriyle devam edilsin mi?',
          'download': 'İndir',
          'cancel': 'Vazgeç',
          'cancelled': 'İndirme iptal edildi.',
          'downloading': 'Güncelleme indiriliyor…',
        },
      });
      if (mounted) setState(() => status = message ?? 'Kontrol tamamlandı.');
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => status =
              error.message ?? 'Güncelleme kontrol edilemedi. Yeniden dene.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => status = 'Güncelleme kontrol edilemedi. Yeniden dene.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.system_update_outlined),
      title: const Text('Güncelle'),
      children: [
        ListTile(
          title: const Text('Güncellemeleri kontrol et'),
          subtitle: Text(status),
          trailing: busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_right),
          onTap: busy ? null : check,
        ),
      ],
    ),
  );
}
