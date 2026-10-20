from pathlib import Path
p=Path('lib/main.dart');s=p.read_text(encoding='utf-8')
s=s.replace("import 'chapter_page.dart';","import 'chapter_page.dart';\nimport 'settings_screen.dart';\nimport 'package:flutter/foundation.dart';")
s=s.replace('  runApp(','''  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Amiri'], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  runApp(''',1)
a=s.index("          IconButton(\n            tooltip: 'Kaynaklar',")
b=s.index('\n        ],\n      ),\n      body:',a)
s=s[:a]+'''          IconButton(tooltip: 'Ayarlar', icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SettingsScreen(prefs: widget.prefs)))),'''+s[b:]
s=s.replace('  late double arSize, trSize;', '  late double arSize, trSize, mealSize;')
s=s.replace('bool controls = true, transcript = false, busy = false;', 'bool controls = true, transcript = false, busy = false;\n  bool meaning = false;')
s=s.replace("    trSize = widget.prefs.getDouble('trSize') ?? 20;", "    trSize = widget.prefs.getDouble('trSize') ?? 20;\n    mealSize = widget.prefs.getDouble('mealSize') ?? 18;\n    fitPage = widget.prefs.getBool('fitPage') ?? true;")
a=s.index('  void settings() => showModalBottomSheet<void>(');b=s.index('  @override\n  Widget build',a)
s=s[:a]+'''  Future<void> settings() async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SettingsScreen(prefs: widget.prefs)));
    if (!mounted) return;
    setState(() {
      arSize = widget.prefs.getDouble('arSize') ?? 32;
      trSize = widget.prefs.getDouble('trSize') ?? 20;
      mealSize = widget.prefs.getDouble('mealSize') ?? 18;
      fitPage = widget.prefs.getBool('fitPage') ?? true;
      arabicLineStarts = widget.prefs.getBool('arabicLineStarts') ?? true;
      transcriptLeftAligned = widget.prefs.getBool('transcriptLeftAligned') ?? false;
    });
  }

  void resize(double amount) {
    final key = meaning ? 'mealSize' : transcript ? 'trSize' : 'arSize';
    final size = meaning ? mealSize : transcript ? trSize : arSize;
    final next = (size + amount).clamp(!transcript && !meaning ? 22.0 : 14.0, !transcript && !meaning ? 64.0 : 40.0);
    setState(() { if (meaning) { mealSize = next; } else if (transcript) { trSize = next; } else { arSize = next; } fitPage = false; });
    widget.prefs.setDouble(key, next);
    widget.prefs.setBool('fitPage', false);
  }
'''+s[b:]
s=s.replace('preferredSize: const Size.fromHeight(48)', 'preferredSize: const Size.fromHeight(56)')
s=s.replace('onPressed: () => setState(() => transcript = false)', 'onPressed: () => setState(() { transcript = false; meaning = false; })')
s=s.replace('color: transcript ? Colors.grey : green', 'color: transcript || meaning ? Colors.grey : green')
s=s.replace('onPressed: () => setState(() => transcript = true)', 'onPressed: () => setState(() { transcript = true; meaning = false; })')
needle="                    Expanded(\n                      child: TextButton(\n                        onPressed: () => setState(() { transcript = true; meaning = false; }),"
at=s.index(needle)
s=s[:at]+'''                    Expanded(child: TextButton(onPressed: () => setState(() { meaning = true; transcript = false; }), child: Text('Meal', style: TextStyle(color: meaning ? green : Colors.grey, fontWeight: FontWeight.bold)))),
'''+s[at:]
at=s.index('\n                  ],\n                ),\n              ),\n              actions:',s.index('class _ReaderState'))
s=s[:at]+'''
                    IconButton(tooltip: 'Yazıyı küçült', onPressed: () => resize(-2), icon: const Text('A−', style: TextStyle(fontSize: 18))),
                    IconButton(tooltip: 'Yazıyı büyüt', onPressed: () => resize(2), icon: const Text('A+', style: TextStyle(fontSize: 18))),
'''+s[at:]
s=s.replace("tooltip: 'Yazı boyutu',", "tooltip: 'Ayarlar',")
s=s.replace('icon: const Icon(Icons.text_fields)', 'icon: const Icon(Icons.settings_outlined)')
s=s.replace("key: ValueKey('$page-$transcript')", "key: ValueKey('$page-$transcript-$meaning')")
s=s.replace('fontSize: transcript ? trSize : arSize,', 'fontSize: meaning ? mealSize : transcript ? trSize : arSize,\n                    meaning: meaning,')
s=s.replace('if (n < 0 || n >= 100 || n == index)', 'if (n < 0 || n >= widget.chapters.length || n == index)')
p.write_text(s,encoding='utf-8')
