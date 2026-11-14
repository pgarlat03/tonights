import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RollScreen extends StatefulWidget {
  final List<String> movies;
  final bool isSeries;

  const RollScreen({
    super.key,
    required this.movies,
    this.isSeries = false,
  });

  @override
  State<RollScreen> createState() => _RollScreenState();
}

class MediaDetails {
  final String title;
  final String posterPath;
  final double rating;
  final String overview;
  final String releaseDate;

  MediaDetails({
    required this.title,
    required this.posterPath,
    required this.rating,
    required this.overview,
    required this.releaseDate,
  });
}

class _RollScreenState extends State<RollScreen> {
  bool _isLoading = true;
  List<MediaDetails> _rankedMedia = [];

  final String _tmdbToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIxOTcwNzI4OTE2OTA2NWIxY2U5MTYyNGYwNWUzOTAzZSIsIm5iZiI6MTc4NjM1OTQzNi44MTEsInN1YiI6IjZhNzlhZThjODM0N2E5MTUwMzZjYzU4YyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.uz-BuRbvT5bh0M-Jod0UGcVYJSK_tAz3IhzH-uprWto';

  @override
  void initState() {
    super.initState();
    _fetchAndRankMedia();
  }

  Future<void> _fetchAndRankMedia() async {
    if (widget.movies.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final random = Random();
    final listCopy = List<String>.from(widget.movies);
    listCopy.shuffle(random);
    
    final selectedTitles = listCopy.take(6).toList();
    List<MediaDetails> fetchedList = [];
    final endpoint = widget.isSeries ? 'tv' : 'movie';

    for (var title in selectedTitles) {
      try {
        final url = Uri.parse(
          'https://api.themoviedb.org/3/search/$endpoint?query=${Uri.encodeComponent(title)}&language=es-ES',
        );
        
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $_tmdbToken',
            'accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = data['results'] as List;

          if (results.isNotEmpty) {
            final itemData = results[0];
            final posterPath = itemData['poster_path'] != null
                ? 'https://image.tmdb.org/t/p/w500${itemData['poster_path']}'
                : '';
            final rating = (itemData['vote_average'] as num?)?.toDouble() ?? 0.0;
            final overview = itemData['overview'] ?? 'Sin sinopsis disponible.';
            
            final dateField = widget.isSeries ? 'first_air_date' : 'release_date';
            final fullDate = itemData[dateField] ?? '';
            final year = fullDate.isNotEmpty && fullDate.length >= 4 ? fullDate.substring(0, 4) : 'N/A';

            final realTitle = widget.isSeries 
                ? (itemData['name'] ?? title) 
                : (itemData['title'] ?? title);

            fetchedList.add(MediaDetails(
              title: realTitle,
              posterPath: posterPath,
              rating: rating,
              overview: overview,
              releaseDate: year,
            ));
          } else {
            fetchedList.add(MediaDetails(
              title: title,
              posterPath: '',
              rating: 0.0,
              overview: 'No se encontró información en la base de datos.',
              releaseDate: 'N/A',
            ));
          }
        }
      } catch (e) {
        fetchedList.add(MediaDetails(
          title: title,
          posterPath: '',
          rating: 0.0,
          overview: 'Error de conexión.',
          releaseDate: 'N/A',
        ));
      }
    }

    fetchedList.sort((a, b) => b.rating.compareTo(a.rating));

    setState(() {
      _rankedMedia = fetchedList;
      _isLoading = false;
    });
  }

  void _showDetailsModal(MediaDetails media, String codeNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 110,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                      image: media.posterPath.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(media.posterPath),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: media.posterPath.isEmpty
                        ? const Center(child: Text('🎬', style: TextStyle(fontSize: 30)))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          media.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$codeNumber • ${widget.isSeries ? "Serie" : "Cine"}',
                          style: const TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0A0A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('📅 ', style: TextStyle(fontSize: 12)),
                                  Text(
                                    media.releaseDate,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A0A0A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('⭐ ', style: TextStyle(fontSize: 12)),
                                  Text(
                                    '${media.rating.toStringAsFixed(1)}/10',
                                    style: const TextStyle(
                                      color: Color(0xFFE0BE4A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Sinopsis',
                style: TextStyle(
                  color: Color(0xFFE0BE4A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                media.overview,
                style: const TextStyle(
                  color: Color(0xFFCCCCCC),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('¡"${media.title}" marcada como vista!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Marcar como Vista (Eliminar)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A0A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            '¡Añade elementos a la lista primero!',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'YOUR 6 PICKS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFE0BE4A)),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchAndRankMedia();
            },
            tooltip: 'Volver a tirar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE0BE4A),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('✨ ', style: TextStyle(fontSize: 16)),
                      Text(
                        'SELECCIÓN DEL CRÍTICO (MEJOR VALORADA)',
                        style: TextStyle(
                          color: Color(0xFFE0BE4A),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_rankedMedia.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => _showDetailsModal(_rankedMedia[0], '#001'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE0BE4A).withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 110,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                                image: _rankedMedia[0].posterPath.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(_rankedMedia[0].posterPath),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _rankedMedia[0].posterPath.isEmpty
                                  ? const Center(child: Text('🎬', style: TextStyle(fontSize: 30)))
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _rankedMedia[0].title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '#001 • Top Rating',
                                    style: TextStyle(
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Text('⭐', style: TextStyle(fontSize: 14)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_rankedMedia[0].rating.toStringAsFixed(1)}/10',
                                        style: const TextStyle(
                                          color: Color(0xFFE0BE4A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Toca para ver detalles ->',
                                    style: TextStyle(
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      const Text('🍿 ', style: TextStyle(fontSize: 16)),
                      Text(
                        'OTRAS ${_rankedMedia.length > 1 ? _rankedMedia.length - 1 : 0} OPCIONES',
                        style: const TextStyle(
                          color: Color(0xFFE0BE4A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _rankedMedia.length > 1 ? _rankedMedia.length - 1 : 0,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final item = _rankedMedia[index + 1];
                      final codeNumber = '#00${index + 2}';

                      return GestureDetector(
                        onTap: () => _showDetailsModal(item, codeNumber),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(16),
                            image: item.posterPath.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(item.posterPath),
                                    fit: BoxFit.cover,
                                    opacity: 0.5,
                                  )
                                : null,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.85),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      codeNumber,
                                      style: const TextStyle(
                                        color: Color(0xFFE0BE4A),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '⭐ ${item.rating.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}