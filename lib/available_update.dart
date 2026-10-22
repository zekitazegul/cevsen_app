class AvailableUpdate {
  const AvailableUpdate(this.version, this.notes);
  final String version;
  final Map<String, String> notes;
  static AvailableUpdate? fromMap(Map<String, dynamic>? data) {
    if (data == null || data['available'] != true) return null;
    final raw = data['releaseNotes'];
    return AvailableUpdate(
      data['versionName'] as String? ?? '',
      raw is Map
          ? {
              for (final entry in raw.entries)
                entry.key.toString(): entry.value.toString(),
            }
          : {},
    );
  }

  String description(String language, String fallback) =>
      (notes[language]?.trim().isNotEmpty == true ? notes[language] : null) ??
      (notes['en']?.trim().isNotEmpty == true ? notes['en'] : null) ??
      fallback;
}
