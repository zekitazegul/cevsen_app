import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

class AudioDownloadCancelled implements Exception {}

class AudioLibrary {
  AudioLibrary({required this.directory, required this.tracks});

  final Directory directory;
  final List<Map<String, dynamic>> tracks;
  HttpClient? _client;
  bool _cancelled = false;

  static Future<AudioLibrary> load() async {
    final path = await const MethodChannel('com.zek.cevsen_app/external')
        .invokeMethod<String>('audioDirectory');
    if (path == null) throw StateError('Ses klasörü açılamadı.');
    final data = jsonDecode(
      await rootBundle.loadString('assets/audio/downloads.json'),
    ) as List;
    return AudioLibrary(
      directory: Directory(path),
      tracks: data.cast<Map<String, dynamic>>(),
    );
  }

  int get totalBytes =>
      tracks.fold(0, (sum, t) => sum + (t['sizeBytes'] as int));

  File fileFor(Map<String, dynamic> track) =>
      File('${directory.path}/${track['file']}');

  Future<bool> _complete(Map<String, dynamic> track) async {
    final file = fileFor(track);
    return await file.exists() && await file.length() == track['sizeBytes'];
  }

  Future<bool> get ready async {
    for (final track in tracks) {
      if (!await _complete(track)) return false;
    }
    return true;
  }

  void cancel() {
    _cancelled = true;
    _client?.close(force: true);
  }

  Future<void> download(
    void Function(int received, int total) onProgress,
  ) async {
    _cancelled = false;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30)
      ..userAgent = 'Cevsen/1.0';
    _client = client;
    var received = 0;
    try {
      await directory.create(recursive: true);
      for (final track in tracks) {
        if (_cancelled) throw AudioDownloadCancelled();
        final size = track['sizeBytes'] as int;
        if (await _complete(track)) {
          received += size;
          onProgress(received, totalBytes);
          continue;
        }
        final target = fileFor(track);
        final partial = File('${target.path}.part');
        IOSink? sink;
        try {
          final request = await client
              .getUrl(Uri.parse(track['url'] as String))
              .timeout(const Duration(seconds: 30));
          request.headers.set(
            HttpHeaders.refererHeader,
            'https://herkul.org/cevsen',
          );
          final response = await request.close().timeout(
            const Duration(seconds: 30),
          );
          if (response.statusCode != HttpStatus.ok) {
            throw HttpException('Ses indirilemedi: ${response.statusCode}');
          }
          var written = 0;
          sink = partial.openWrite();
          await for (final chunk in response.timeout(
            const Duration(seconds: 30),
          )) {
            if (_cancelled) throw AudioDownloadCancelled();
            written += chunk.length;
            if (written > size) {
              throw const FormatException('Ses boyutu değişmiş.');
            }
            sink.add(chunk);
            // Bound buffered data when storage is slower than the network.
            await sink.flush();
            onProgress(received + written, totalBytes);
          }
          await sink.close();
          sink = null;
          if (_cancelled) throw AudioDownloadCancelled();
          if (written != size) {
            throw const FormatException('Ses indirmesi eksik.');
          }
          if (await target.exists()) await target.delete();
          await partial.rename(target.path);
          received += size;
        } finally {
          await sink?.close();
          if (await partial.exists()) await partial.delete();
        }
      }
    } catch (_) {
      if (_cancelled) throw AudioDownloadCancelled();
      rethrow;
    } finally {
      client.close(force: true);
      _client = null;
    }
  }
}
