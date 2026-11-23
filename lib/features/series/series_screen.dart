import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../roll/roll_screen.dart';
import 'series_entry.dart';
import 'series_manager_sheet.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  List<SeriesEntry> _series = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _series = (prefs.getStringList('saved_series') ?? [])
          .map(SeriesEntry.parse)
          .toList();
    });
  }

  Future<void> _saveSeries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_series', _series.map((s) => s.encode()).toList());
  }

  void _addSeries() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _series.add(SeriesEntry(text));
        _controller.clear();
      });
      _saveSeries();
    }
  }

  /// Llamado desde la pantalla de las 6 elecciones al pulsar "Marcar como vista".
  void _removeByTitle(String title) {
    final i = _series.indexWhere((s) => s.title == title);
    if (i == -1) return;
    setState(() => _series.removeAt(i));
    _saveSeries();
  }

  void _showManagementDialog() {
    showSeriesManagerSheet(
      context,
      series: _series,
      onChanged: () {
        if (mounted) setState(() {});
        _saveSeries();
      },
    );
  }

  void _showBulkImportDialog() {
    final TextEditingController bulkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Importar series masivas',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: bulkController,
            maxLines: 10,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Pega aquí tus series (una por línea)...',
              hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE0BE4A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final text = bulkController.text;
              if (text.isNotEmpty) {
                final lines = text
                    .split('\n')
                    .map((item) => item.trim())
                    .where((item) => item.isNotEmpty)
                    .map((item) => SeriesEntry(item))
                    .toList();

                setState(() {
                  _series.addAll(lines);
                });
                _saveSeries();
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Añadir todas',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanTitles = _series.map((s) => s.title).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "TONIGHT'S SERIES",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _showManagementDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE0BE4A).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📺', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      '${_series.length} pendientes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C1E),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🎲',
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Qué toca maratonear hoy?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tira los dados para obtener opciones instantáneas.',
              style: TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RollScreen(
                        movies: cleanTitles,
                        isSeries: true,
                        onMarkWatched: _removeByTitle,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0BE4A),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '🎲 ROLL 6',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Añadir serie suelta...',
                        hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (_) => _addSeries(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addSeries,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _showManagementDialog,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1E),
                  foregroundColor: const Color(0xFFE0BE4A),
                  side: BorderSide(color: const Color(0xFFE0BE4A).withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📺', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text(
                      'Mi progreso (temporada y capítulo)',
                      style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _showBulkImportDialog,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1E),
                  foregroundColor: Colors.white,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📝', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text(
                      'Importar desde Bloc de Notas',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}