import 'dart:io';

import 'package:cevsen_app/audio_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late HttpServer server;
  late AudioLibrary library;
  var requests = <String>[];
  var failSecond = false;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cevsen-audio-test');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    requests = [];
    failSecond = false;
    server.listen((request) async {
      requests.add(request.uri.path);
      if (failSecond && request.uri.path == '/2.mp3') {
        request.response.statusCode = 503;
      } else {
        request.response.add([1, 2, 3, 4]);
      }
      await request.response.close();
    });
    library = AudioLibrary(
      directory: directory,
      tracks: [
        for (var i = 1; i <= 2; i++)
          {
            'file': '$i.mp3',
            'url': 'http://127.0.0.1:${server.port}/$i.mp3',
            'sizeBytes': 4,
          },
      ],
    );
  });

  tearDown(() async {
    library.cancel();
    await server.close(force: true);
    await directory.delete(recursive: true);
  });

  test(
    'Downloads all tracks once and reuses complete local recordings',
    () async {
      expect(await library.ready, isFalse);
      var received = 0;
      await library.download((value, total) {
        expect(total, 8);
        received = value;
      });
      expect(received, 8);
      expect(await library.ready, isTrue);
      expect(requests, ['/1.mp3', '/2.mp3']);
      await library.download((_, _) {});
      expect(requests.length, 2);
    },
  );

  test(
    'Failure keeps completed tracks and retry fetches only missing files',
    () async {
      failSecond = true;
      await expectLater(
        library.download((_, _) {}),
        throwsA(isA<HttpException>()),
      );
      expect(await library.ready, isFalse);
      expect(await File('${directory.path}/1.mp3').length(), 4);
      expect(await File('${directory.path}/2.mp3.part').exists(), isFalse);
      failSecond = false;
      await library.download((_, _) {});
      expect(requests, ['/1.mp3', '/2.mp3', '/2.mp3']);
      expect(await library.ready, isTrue);
    },
  );

  test('Cancellation removes partial files and allows a later retry', () async {
    await expectLater(
      library.download((_, _) => library.cancel()),
      throwsA(isA<AudioDownloadCancelled>()),
    );
    expect(await library.ready, isFalse);
    expect(
      directory.listSync().where((f) => f.path.endsWith('.part')),
      isEmpty,
    );
    await library.download((_, _) {});
    expect(await library.ready, isTrue);
  });

  test('Rejects truncated downloads instead of marking them ready', () async {
    library.tracks[0]['sizeBytes'] = 8;
    await expectLater(library.download((_, _) {}), throwsFormatException);
    expect(await library.ready, isFalse);
    expect(directory.listSync(), isEmpty);
  });
}
