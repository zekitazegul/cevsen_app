import 'package:flutter/material.dart';

import 'audio_library.dart';

class AudioDownloadDialog extends StatefulWidget {
  const AudioDownloadDialog({super.key, required this.library});
  final AudioLibrary library;

  @override
  State<AudioDownloadDialog> createState() => _AudioDownloadDialogState();
}

class _AudioDownloadDialogState extends State<AudioDownloadDialog> {
  bool downloading = false;
  double progress = 0;
  String? error;

  @override
  void dispose() {
    widget.library.cancel();
    super.dispose();
  }

  Future<void> download() async {
    setState(() {
      downloading = true;
      error = null;
    });
    try {
      await widget.library.download((received, total) {
        final next = received / total;
        if (mounted && (next * 100).floor() != (progress * 100).floor()) {
          setState(() => progress = next);
        }
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          downloading = false;
          error = 'İndirme tamamlanamadı. İnternet bağlantını ve boş alanı kontrol edip yeniden dene. İnen dosyalar korunur.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Ses kayıtlarını indir'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tüm bablar ve kapanış duası bir kez indirilir (${(widget.library.totalBytes / 1000000).ceil()} MB). Ardından internet olmadan dinleyebilirsin. Wi-Fi bağlantısı önerilir.',
        ),
        if (downloading) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Text('İndiriliyor… %${(progress * 100).floor()}'),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Vazgeç'),
      ),
      if (!downloading)
        FilledButton(
          onPressed: download,
          child: Text(error == null ? 'İndir' : 'Yeniden dene'),
        ),
    ],
  );
}
