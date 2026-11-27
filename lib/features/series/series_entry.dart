/// Una serie en seguimiento con su progreso.
///
/// Se guarda como "Título:::Temporada:::Capítulo" para ser compatible con
/// los datos que ya tengas guardados en el móvil.
class SeriesEntry {
  String title;
  int season;
  int episode;

  /// true = ya la has empezado a ver (sale en "Empezadas" y NO entra en el Roll 6).
  bool started;

  SeriesEntry(this.title, {this.season = 1, this.episode = 1, this.started = false});

  factory SeriesEntry.parse(String raw) {
    final parts = raw.split(':::');
    final season = parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1;
    final episode = parts.length > 2 ? (int.tryParse(parts[2]) ?? 1) : 1;
    // Datos antiguos (sin 4º campo): se consideran empezadas si pasan de T1·C1
    final started = parts.length > 3 ? parts[3] == '1' : (season > 1 || episode > 1);
    return SeriesEntry(parts[0], season: season, episode: episode, started: started);
  }

  String encode() => '$title:::$season:::$episode:::${started ? 1 : 0}';
}
