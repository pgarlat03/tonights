import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../roll/roll_screen.dart';

class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  // Formato: "Título:::Temporada:::Capítulo"
  List<String> _series = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSeries();
  }

  Future<void> _loadSeries() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _series = prefs.getStringList('saved_series') ?? [];
    });
  }

  Future<void> _saveSeries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_series', _series);
  }

  void _addSeries() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _series.add('$text:::1:::1');
        _controller.clear();
      });
      _saveSeries();
    }
  }

  String _getTitle(String item) {
    final parts = item.split(':::');
    return parts[0];
  }

  int _getSeason(String item) {
    final parts = item.split(':::');
    if (parts.length > 1) {
      return int.tryParse(parts[1]) ?? 1;
    }
    return 1;
  }

  int _getEpisode(String item) {
    final parts = item.split(':::');
    if (parts.length > 2) {
      return int.tryParse(parts[2]) ?? 1;
    }
    return 1;
  }

  void _updateProgress(int index, int newSeason, int newEpisode) {
    if (newSeason < 1) newSeason = 1;
    if (newEpisode < 1) newEpisode = 1;
    
    final title = _getTitle(_series[index]);
    setState(() {
      _series[index] = '$title:::$newSeason:::$newEpisode';
    });
    _saveSeries();
  }

  // Diálogo de gestión ultra-intuitivo con diseño moderno
  void _showManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso de Series',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_series.length}',
                  style: const TextStyle(color: Color(0xFFE0BE4A), fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: _series.isEmpty
                ? const Center(
                    child: Text(
                      'No hay series en seguimiento.',
                      style: TextStyle(color: Color(0xFF9E9E9E)),
                    ),
                  )
                : ListView.builder(
                    itemCount: _series.length,
                    itemBuilder: (context, index) {
                      final item = _series[index];
                      final title = _getTitle(item);
                      final season = _getSeason(item);
                      final episode = _getEpisode(item);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título y botón de borrar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _series.removeAt(index);
                                    });
                                    setDialogState(() {});
                                    _saveSeries();
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            
                            // Selectores visuales en formato píldora
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Control de Temporada
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C1C1E),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('T', style: TextStyle(color: Color(0xFFE0BE4A), fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          if (season > 1) {
                                            _updateProgress(index, season - 1, episode);
                                            setDialogState(() {});
                                          }
                                        },
                                        child: const Icon(Icons.remove, color: Colors.white70, size: 16),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          '$season',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          _updateProgress(index, season + 1, episode);
                                          setDialogState(() {});
                                        },
                                        child: const Icon(Icons.add, color: Colors.white70, size: 16),
                                      ),
                                    ],
                                  ),
                                ),

                                // Control de Capítulo
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1C1C1E),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('C', style: TextStyle(color: Color(0xFFE0BE4A), fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          if (episode > 1) {
                                            _updateProgress(index, season, episode - 1);
                                            setDialogState(() {});
                                          }
                                        },
                                        child: const Icon(Icons.remove, color: Colors.white70, size: 16),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          '$episode',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          _updateProgress(index, season, episode + 1);
                                          setDialogState(() {});
                                        },
                                        child: const Icon(Icons.add, color: Colors.white70, size: 16),
                                      ),
                                      const SizedBox(width: 4),
                                      // Botón rápido para avanzar capítulo siguiente
                                      GestureDetector(
                                        onTap: () {
                                          _updateProgress(index, season, episode + 1);
                                          setDialogState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0BE4A).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.done, color: Color(0xFFE0BE4A), size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: Color(0xFFE0BE4A))),
            ),
          ],
        ),
      ),
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
                    .map((item) => '$item:::1:::1')
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
    final cleanTitles = _series.map((s) => _getTitle(s)).toList();

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
                      builder: (context) => RollScreen(movies: cleanTitles, isSeries: true),
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
                    const SizedBox(width: 8),
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