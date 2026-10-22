import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'chapter_page.dart';
import 'settings_screen.dart';
import 'screen_awake.dart';
import 'audio_library.dart';
import 'audio_download_dialog.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const green = Color(0xff123f35),
    gold = Color(0xffb8914b),
    paper = Color(0xfffaf5e9);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await setScreenAwake(prefs.getBool('keepScreenOn') ?? true);
  final chapters =
      jsonDecode(await rootBundle.loadString('assets/cevsen.json')) as List;
  final audio = jsonDecode(
    await rootBundle.loadString('assets/audio/chapters.json'),
  ) as List;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Amiri',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  runApp(
    MaterialApp(
      title: 'Cevşen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(seedColor: green, surface: paper),
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: green,
          centerTitle: true,
        ),
      ),
      home: Library(prefs: prefs, chapters: chapters, audio: audio),
    ),
  );
}

class Emblem extends StatelessWidget {
  const Emblem({super.key, this.size = 64});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .22),
      child: Image.asset('assets/branding/cevsen-logo.png'),
    ),
  );
}

class Motif extends CustomPainter {
  Motif({this.logo = false});
  final bool logo;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2),
        r = math.min(size.width, size.height) * .42;
    final pen = Paint()
      ..color = gold.withValues(alpha: logo ? 1 : .32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = logo ? 1.8 : 1;
    if (logo) canvas.drawCircle(c, r * 1.15, Paint()..color = green);
    for (final angle in [0.0, math.pi / 4]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: r * 1.42, height: r * 1.42),
        pen,
      );
      canvas.restore();
    }
    if (logo) {
      final p = Path()
        ..moveTo(c.dx, c.dy + r * .43)
        ..quadraticBezierTo(
          c.dx - r * .3,
          c.dy + r * .13,
          c.dx - r * .55,
          c.dy + r * .23,
        )
        ..lineTo(c.dx - r * .55, c.dy - r * .32)
        ..quadraticBezierTo(c.dx - r * .3, c.dy - r * .44, c.dx, c.dy - r * .12)
        ..quadraticBezierTo(
          c.dx + r * .3,
          c.dy - r * .44,
          c.dx + r * .55,
          c.dy - r * .32,
        )
        ..lineTo(c.dx + r * .55, c.dy + r * .23)
        ..quadraticBezierTo(
          c.dx + r * .3,
          c.dy + r * .13,
          c.dx,
          c.dy + r * .43,
        );
      canvas.drawPath(p, Paint()..color = paper);
      canvas.drawLine(
        Offset(c.dx, c.dy - r * .12),
        Offset(c.dx, c.dy + r * .43),
        pen,
      );
    }
  }

  @override
  bool shouldRepaint(Motif old) => old.logo != logo;
}

String chapterTitle(dynamic b) {
  final rows = b['rows'] as List;
  return rows[rows.length == 12 ? 1 : 0]['tr'] as String;
}

class Library extends StatefulWidget {
  const Library({
    super.key,
    required this.prefs,
    required this.chapters,
    required this.audio,
  });
  final SharedPreferences prefs;
  final List chapters, audio;
  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  Future<void> open(int n) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Reader(
          prefs: widget.prefs,
          chapters: widget.chapters,
          audio: widget.audio,
          initial: n,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.chapters;
    final last = widget.prefs.getInt('last') ?? 0;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Çıkış',
          onPressed: () => SystemNavigator.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Cevşen-i Kebîr'),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(prefs: widget.prefs),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  children: [
                    Material(
                      color: green,
                      borderRadius: BorderRadius.circular(22),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: const Icon(
                          Icons.auto_stories_outlined,
                          color: gold,
                          size: 32,
                        ),
                        title: const Text(
                          'Kaldığın yerden devam et',
                          style: TextStyle(color: paper),
                        ),
                        subtitle: Text(
                          widget.chapters[last]['title'] as String? ??
                              '${last + 1}. Bab',
                          style: const TextStyle(color: gold),
                        ),
                        trailing: const Icon(Icons.arrow_forward, color: paper),
                        onTap: () => open(last),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('Aramana uygun bab bulunamadı.'),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final b = items[i], n = b['number'] as int;
                  return Card(
                    elevation: 0,
                    color: Colors.white70,
                    margin: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      dense: true,
                      minTileHeight: 48,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      title: Text(
                        b['title'] as String? ?? '$n. Bab',
                        style: const TextStyle(
                          color: green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: gold),
                      onTap: () => open(n - 1),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Reader extends StatefulWidget {
  const Reader({
    super.key,
    required this.prefs,
    required this.chapters,
    required this.audio,
    required this.initial,
  });
  final SharedPreferences prefs;
  final List chapters, audio;
  final int initial;
  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  final player = AudioPlayer();
  late int index;
  late double arSize, trSize, mealSize;
  bool controls = true, transcript = false, busy = false;
  bool meaning = false;
  bool fitPage = true;
  bool pageEffect = true;
  double dragDistance = 0;
  late bool arabicLineStarts;
  late bool transcriptLeftAligned;
  late final PageController pages;
  int? loaded;
  int? audioPage;
  int playlistStart = 0;
  StreamSubscription<int?>? audioIndexSubscription;
  @override
  void initState() {
    super.initState();
    index = widget.initial;
    pages = PageController(initialPage: index);
    arSize = widget.prefs.getDouble('arSize') ?? 32;
    trSize = widget.prefs.getDouble('trSize') ?? 20;
    mealSize = widget.prefs.getDouble('mealSize') ?? 18;
    fitPage = widget.prefs.getBool('fitPage') ?? true;
    pageEffect = widget.prefs.getBool('pageEffect') ?? true;
    arabicLineStarts = widget.prefs.getBool('arabicLineStarts') ?? true;
    transcriptLeftAligned =
        widget.prefs.getBool('transcriptLeftAligned') ?? false;
    widget.prefs.setInt('last', index);
    audioIndexSubscription = player.currentIndexStream.listen((track) {
      if (!mounted || loaded == null || track == null) return;
      final next = playlistStart + track;
      if (next == index) return;
      audioPage = next;
      jump(next);
    });
  }

  @override
  void dispose() {
    audioIndexSubscription?.cancel();
    pages.dispose();
    player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void jump(int n) {
    if (n < 0 || n >= widget.chapters.length || n == index) return;
    if (!pageEffect) {
      pages.jumpToPage(n);
      return;
    }
    pages.animateToPage(
      n,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void selectedPage(int n) {
    if (audioPage != n) {
      loaded = null;
      player.stop();
    }
    audioPage = null;
    setState(() => index = n);
    widget.prefs.setInt('last', n);
  }

  Future<void> listen() async {
    if (busy) return;
    if (player.playing && player.processingState != ProcessingState.completed) {
      await player.pause();
      return;
    }
    int? mode;
    if (loaded == null || player.processingState == ProcessingState.completed) {
      mode = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.headphones_outlined),
                title: const Text('Bu babı dinle'),
                onTap: () => Navigator.pop(context, 0),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_play),
                title: const Text('Bu babdan sonuna kadar dinle'),
                onTap: () => Navigator.pop(context, 1),
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Cevşen’in tamamını dinle'),
                subtitle: const Text('1. babdan başlar'),
                onTap: () => Navigator.pop(context, 2),
              ),
            ],
          ),
        ),
      );
      if (!mounted || mode == null) return;
    }
    setState(() => busy = true);
    try {
      final requested = index;
      if (mode != null) {
        final library = await AudioLibrary.load();
        if (!await library.ready) {
          if (!mounted) return;
          final downloaded = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AudioDownloadDialog(library: library),
          );
          if (downloaded != true) return;
        }
        if (!mounted || index != requested) return;
        loaded = null;
        playlistStart = mode == 2 ? 0 : requested;
        final end = mode == 0 ? requested + 1 : widget.audio.length;
        await player.setAudioSources([
          for (final t in widget.audio.sublist(playlistStart, end))
            ClippingAudioSource(
              child: AudioSource.file('${library.directory.path}/${t['file']}'),
              start: Duration(milliseconds: t['startMs'] as int),
              end: Duration(milliseconds: t['endMs'] as int),
            ),
        ]);
        if (!mounted || index != requested) {
          await player.stop();
          return;
        }
        loaded = requested;
        if (playlistStart != index) {
          audioPage = playlistStart;
          pages.jumpToPage(playlistStart);
        }
      }
      unawaited(player.play());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ses açılamadı. Yeniden deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void toggle() {
    setState(() => controls = !controls);
    SystemChrome.setEnabledSystemUIMode(
      controls ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  void selectLayout(bool startAligned) {
    if (transcript) {
      setState(() => transcriptLeftAligned = startAligned);
      widget.prefs.setBool('transcriptLeftAligned', startAligned);
    } else {
      setState(() => arabicLineStarts = startAligned);
      widget.prefs.setBool('arabicLineStarts', startAligned);
    }
  }

  Future<void> settings() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(prefs: widget.prefs),
      ),
    );
    if (!mounted) return;
    setState(() {
      arSize = widget.prefs.getDouble('arSize') ?? 32;
      trSize = widget.prefs.getDouble('trSize') ?? 20;
      mealSize = widget.prefs.getDouble('mealSize') ?? 18;
      fitPage = widget.prefs.getBool('fitPage') ?? true;
      pageEffect = widget.prefs.getBool('pageEffect') ?? true;
      arabicLineStarts = widget.prefs.getBool('arabicLineStarts') ?? true;
      transcriptLeftAligned =
          widget.prefs.getBool('transcriptLeftAligned') ?? false;
    });
  }

  void resize(double amount) {
    final key = meaning
        ? 'mealSize'
        : transcript
        ? 'trSize'
        : 'arSize';
    final size = meaning
        ? mealSize
        : transcript
        ? trSize
        : arSize;
    final next = (size + amount).clamp(
      !transcript && !meaning ? 22.0 : 14.0,
      !transcript && !meaning ? 64.0 : 40.0,
    );
    setState(() {
      if (meaning) {
        mealSize = next;
      } else if (transcript) {
        trSize = next;
      } else {
        arSize = next;
      }
      fitPage = false;
    });
    widget.prefs.setDouble(key, next);
    widget.prefs.setBool('fitPage', false);
  }

  @override
  Widget build(BuildContext context) {
    final startAligned = transcript ? transcriptLeftAligned : arabicLineStarts;
    return Scaffold(
      appBar: controls
          ? AppBar(
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final measure = TextPainter(
                      text: const TextSpan(
                        text: 'T\u00fcrk\u00e7e okunu\u015f',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      textDirection: TextDirection.ltr,
                      textScaler: MediaQuery.textScalerOf(context),
                    )..layout();
                    final labelSize =
                        14 *
                        math.min(
                          1.0,
                          (constraints.maxWidth / 3 - 32) / measure.width,
                        );
                    measure.dispose();
                    return Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() {
                              transcript = false;
                              meaning = false;
                            }),
                            child: Text(
                              'Arapça',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: labelSize.toDouble(),
                                color: transcript || meaning
                                    ? Colors.grey
                                    : green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() {
                              transcript = true;
                              meaning = false;
                            }),
                            child: Text(
                              'Türkçe okunuş',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: labelSize.toDouble(),
                                color: transcript ? green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() {
                              meaning = true;
                              transcript = false;
                            }),
                            child: Text(
                              'Meal',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: labelSize.toDouble(),
                                color: meaning ? green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                if (!meaning) ...[
                  IconButton(
                    tooltip: 'Ortala',
                    isSelected: !startAligned,
                    style: IconButton.styleFrom(
                      backgroundColor: !startAligned
                          ? gold.withValues(alpha: .22)
                          : Colors.transparent,
                    ),
                    onPressed: () => selectLayout(false),
                    icon: const Icon(Icons.format_align_center, size: 20),
                  ),
                  IconButton(
                    tooltip: transcript ? 'Sola dayalı' : 'Sağdan başla',
                    isSelected: startAligned,
                    style: IconButton.styleFrom(
                      backgroundColor: startAligned
                          ? gold.withValues(alpha: .22)
                          : Colors.transparent,
                    ),
                    onPressed: () => selectLayout(true),
                    icon: Icon(
                      transcript
                          ? Icons.format_align_left
                          : Icons.format_align_right,
                      size: 20,
                    ),
                  ),
                ],
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snapshot) => IconButton(
                    tooltip:
                        snapshot.data?.playing == true &&
                            snapshot.data?.processingState !=
                                ProcessingState.completed
                        ? 'Duraklat'
                        : 'Dinle',
                    onPressed: busy ? null : listen,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            snapshot.data?.playing == true &&
                                    snapshot.data?.processingState !=
                                        ProcessingState.completed
                                ? Icons.pause
                                : Icons.headphones_outlined,
                          ),
                  ),
                ),

                IconButton(
                  tooltip: 'Yazıyı küçült',
                  onPressed: () => resize(-2),
                  icon: FittedBox(
                    child: Text('A−', style: const TextStyle(fontSize: 18)),
                  ),
                ),
                IconButton(
                  tooltip: 'Yazıyı büyüt',
                  onPressed: () => resize(2),
                  icon: const FittedBox(
                    child: Text('A+', style: TextStyle(fontSize: 18)),
                  ),
                ),
                IconButton(
                  tooltip: 'Ayarlar',
                  onPressed: settings,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ].map((action) => SizedBox(width: 38, child: action)).toList(),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: toggle,
                onHorizontalDragStart: pageEffect
                    ? null
                    : (_) => dragDistance = 0,
                onHorizontalDragUpdate: pageEffect
                    ? null
                    : (d) => dragDistance += d.delta.dx,
                onHorizontalDragEnd: pageEffect
                    ? null
                    : (d) {
                        final speed = d.primaryVelocity ?? 0;
                        if (dragDistance.abs() > 40 || speed.abs() > 160) {
                          jump(
                            index +
                                ((dragDistance.abs() > 40
                                            ? dragDistance
                                            : speed) <
                                        0
                                    ? 1
                                    : -1),
                          );
                        }
                      },
                child: PageView.builder(
                  physics: pageEffect
                      ? null
                      : const NeverScrollableScrollPhysics(),
                  controller: pages,
                  itemCount: widget.chapters.length,
                  onPageChanged: selectedPage,
                  itemBuilder: (context, page) => StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, snapshot) => ChapterPage(
                      key: ValueKey(
                        '$page-$transcript-$meaning-${page == index}',
                      ),
                      number: page + 1,
                      heading: widget.chapters[page]['title'] as String?,
                      rows: widget.chapters[page]['rows'] as List,
                      transcript: transcript,
                      fontSize: meaning
                          ? mealSize
                          : transcript
                          ? trSize
                          : arSize,
                      meaning: meaning,
                      fitPage: fitPage,
                      arabicLineStarts: arabicLineStarts,
                      transcriptLeftAligned: transcriptLeftAligned,
                      readingProgress:
                          loaded != null &&
                              playlistStart + (player.currentIndex ?? 0) ==
                                  page &&
                              page < widget.audio.length
                          ? (player.position.inMilliseconds /
                                    ((widget.audio[page]['endMs'] as int) -
                                        (widget.audio[page]['startMs'] as int)))
                                .clamp(0.0, 1.0)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
