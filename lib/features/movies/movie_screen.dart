import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../roll/roll_screen.dart';

class MovieScreen extends StatefulWidget {
  const MovieScreen({super.key});

  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  List<String> _movies = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMovies(); // Carga las películas guardadas al abrir la app
  }

  // Cargar películas desde la memoria del móvil
  Future<void> _loadMovies() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _movies = prefs.getStringList('saved_movies') ?? [];
    });
  }

  // Guardar películas en la memoria del móvil
  Future<void> _saveMovies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_movies', _movies);
  }

  // Llamado desde la pantalla de las 6 elecciones al pulsar "Marcar como vista"
  void _removeByTitle(String title) {
    final i = _movies.indexOf(title);
    if (i == -1) return;
    setState(() => _movies.removeAt(i));
    _saveMovies();
  }

  void _addMovie() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        _movies.add(_controller.text.trim());
        _controller.clear();
      });
      _saveMovies(); // Guarda automáticamente al añadir una peli
    }
  }

  // Diálogo para gestionar/eliminar las películas guardadas desde el botón superior
  void _showManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Películas pendientes',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                '(${_movies.length})',
                style: const TextStyle(color: Color(0xFFE0BE4A), fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: _movies.isEmpty
                ? const Center(
                    child: Text(
                      'No hay películas en la lista.',
                      style: TextStyle(color: Color(0xFF9E9E9E)),
                    ),
                  )
                : ListView.builder(
                    itemCount: _movies.length,
                    itemBuilder: (context, index) {
                      final movie = _movies[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            movie,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              setState(() {
                                _movies.removeAt(index);
                              });
                              setDialogState(() {}); // Actualiza el diálogo al momento
                              _saveMovies();         // Guarda cambios en el móvil
                            },
                          ),
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
        title: const Text(
          'Importar lista masiva',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: bulkController,
            maxLines: 10,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Pega aquí tus películas (una por línea)...',
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
            ),
            onPressed: () {
              final text = bulkController.text;
              if (text.isNotEmpty) {
                final lines = text
                    .split('\n')
                    .map((movie) => movie.trim())
                    .where((movie) => movie.isNotEmpty)
                    .toList();

                setState(() {
                  _movies.addAll(lines);
                });
                _saveMovies(); // Guarda tras la importación masiva
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "TONIGHT'S MOVIE",
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
              onTap: _showManagementDialog, // <-- Abre el gestor al pulsar el contador
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
                    const Text('🍿', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      '${_movies.length} pendientes',
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
              '¿Qué toca ver hoy?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
                        movies: List<String>.from(_movies),
                        isSeries: false,
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
                        hintText: 'Añadir peli suelta...',
                        hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (_) => _addMovie(),
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
                    onPressed: _addMovie,
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