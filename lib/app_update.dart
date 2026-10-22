import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'available_update.dart';

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
  bool busy = false, checking = false;
  AvailableUpdate? available;
  bool revealed = false;
  String? checkError;
  String installedVersion = '';
  bool installing = false;
  String status =
      'Güncellemeyi indirmek internet verisi kullanır. Wi-Fi bağlantısı önerilir.';

  @override
  void initState() {
    super.initState();
    check();
    channel.setMethodCallHandler((call) async {
      if (mounted && call.method == 'status') {
        setState(() => status = call.arguments as String);
      }
    });
  }

  void toggleUpdates() {
    if (revealed) {
      setState(() => revealed = false);
    } else if (checking || busy) {
      setState(() => revealed = true);
    } else {
      check(force: true);
    }
  }

  Future<void> check({bool force = false}) async {
    if (checking) return;
    setState(() {
      checking = true;
      if (force) {
        revealed = true;
        checkError = null;
        installing = false;
      }
    });
    try {
      final data = await channel.invokeMapMethod<String, dynamic>(
        'checkUpdate',
        {'manifestUrl': updateManifestUrl, 'force': force},
      );
      if (mounted) {
        setState(() {
          available = AvailableUpdate.fromMap(data);
          installedVersion = data?['installedVersionName'] as String? ?? '';
        });
      }
    } catch (_) {
      if (mounted && force) {
        setState(
          () => checkError =
              'Sürüm bilgisi alınamadı. Bağlantını kontrol edip yeniden dene.',
        );
      }
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  @override
  void dispose() {
    channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> install() async {
    if (busy) return;
    setState(() {
      busy = true;
      installing = true;
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
    child: Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.system_update_outlined),
            title: Row(
              children: [
                Expanded(child: Text('Güncellemeler')),
                if (available != null) Badge(label: Text('Yeni')),
              ],
            ),
            trailing: checking && revealed
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(revealed ? Icons.expand_less : Icons.expand_more),
            onTap: toggleUpdates,
          ),
          if (revealed && !checking)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  if (checkError != null)
                    Semantics(liveRegion: true, child: Text(checkError!))
                  else if (available == null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        'Uygulama zaten en güncel durumda.${installedVersion.isEmpty ? '' : ' Sürüm: $installedVersion'}',
                      ),
                    )
                  else ...[
                    Text(
                      'Yeni sürüm: ${available!.version}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(available!.description('tr', 'Yeni sürüm hazır.')),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: busy ? null : install,
                      icon: const Icon(Icons.download_outlined),
                      label: Text('Güncelle'),
                    ),
                  ],
                  if (installing)
                    Semantics(liveRegion: true, child: Text(status)),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
