/// Una serie en seguimiento con su progreso.
///
/// Se guarda como "Título:::Temporada:::Capítulo" para ser compatible con
/// los datos que ya tengas guardados en el móvil.
class SeriesEntry {
  String title;
  int season;
  int episode;

  SeriesEntry(this.title, {this.season = 1, this.episode = 1});

  factory SeriesEntry.parse(String raw) {
    final parts = raw.split(':::');
    return SeriesEntry(
      parts[0],
      season: parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1,
      episode: parts.length > 2 ? (int.tryParse(parts[2]) ?? 1) : 1,
    );
  }

  String encode() => '$title:::$season:::$episode';
}
