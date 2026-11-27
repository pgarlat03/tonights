import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'series_entry.dart';

const _gold = Color(0xFFE0BE4A);
const _surface = Color(0xFF1C1C1E);
const _bg = Color(0xFF0A0A0A);
const _muted = Color(0xFF9E9E9E);

/// Panel inferior para ver y actualizar el progreso (temporada / capítulo)
/// de todas las series. Modifica directamente los [SeriesEntry] de [series]
/// y avisa con [onChanged] para que quien lo abre guarde y refresque.
Future<void> showSeriesManagerSheet(
  BuildContext context, {
  required List<SeriesEntry> series,
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => _SeriesManager(
        series: series,
        onChanged: onChanged,
        scrollController: scrollController,
      ),
    ),
  );
}

class _SeriesManager extends StatefulWidget {
  final List<SeriesEntry> series;
  final VoidCallback onChanged;
  final ScrollController scrollController;

  const _SeriesManager({
    required this.series,
    required this.onChanged,
    required this.scrollController,
  });

  @override
  State<_SeriesManager> createState() => _SeriesManagerState();
}

class _SeriesManagerState extends State<_SeriesManager> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  late bool _showStarted;

  @override
  void initState() {
    super.initState();
    // Abre en "Empezadas" si ya hay alguna; si no, en "Pendientes"
    _showStarted = widget.series.any((s) => s.started);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _apply(SeriesEntry entry, {int? season, int? episode}) {
    HapticFeedback.selectionClick();
    setState(() {
      entry.started = true; // tocar el progreso = la has empezado
      entry.season = (season ?? entry.season).clamp(1, 999).toInt();
      entry.episode = (episode ?? entry.episode).clamp(1, 9999).toInt();
    });
    widget.onChanged();
  }

  void _start(SeriesEntry entry) {
    HapticFeedback.mediumImpact();
    setState(() => entry.started = true);
    widget.onChanged();
  }

  Future<void> _askNumber(String label, int current, ValueChanged<int> onValue) async {
    final controller = TextEditingController(text: '$current');
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        void submit() {
          final v = int.tryParse(controller.text.trim());
          Navigator.pop(dialogContext, v);
        }

        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            onSubmitted: (_) => submit(),
            decoration: InputDecoration(
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: submit,
              child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result != null && result >= 1) onValue(result);
  }

  Future<void> _confirmDelete(SeriesEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('¿Quitar de la lista?', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Text(
          '"${entry.title}" se eliminará junto con su progreso '
          '(T${entry.season} · C${entry.episode}).',
          style: const TextStyle(color: Color(0xFFCCCCCC)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Quitar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => widget.series.remove(entry));
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final startedCount = widget.series.where((s) => s.started).length;
    final pendingCount = widget.series.length - startedCount;
    final visible = widget.series
        .where((s) => s.started == _showStarted)
        .where((s) => q.isEmpty || s.title.toLowerCase().contains(q))
        .toList();

    return Column(
      children: [
        // Tirador
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Mi progreso',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${widget.series.length} series',
                  style: const TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _SegmentButton(
                  label: 'Empezadas ($startedCount)',
                  selected: _showStarted,
                  onTap: () => setState(() => _showStarted = true),
                ),
                _SegmentButton(
                  label: 'Pendientes ($pendingCount)',
                  selected: !_showStarted,
                  onTap: () => setState(() => _showStarted = false),
                ),
              ],
            ),
          ),
        ),
        if (widget.series.length > 4)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar serie...',
                hintStyle: const TextStyle(color: _muted),
                prefixIcon: const Icon(Icons.search, color: _muted),
                filled: true,
                fillColor: _bg,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        Expanded(
          child: visible.isEmpty
              ? ListView(
                  controller: widget.scrollController,
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Text(
                        widget.series.isEmpty
                            ? 'No hay series en seguimiento.'
                            : q.isNotEmpty
                                ? 'Ninguna serie coincide.'
                                : _showStarted
                                    ? 'Aún no has empezado ninguna serie.'
                                    : 'No tienes series pendientes.',
                        style: const TextStyle(color: _muted),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final entry = visible[i];
                    if (!entry.started) {
                      return _PendingCard(
                        key: ObjectKey(entry),
                        entry: entry,
                        onStart: () => _start(entry),
                        onDelete: () => _confirmDelete(entry),
                      );
                    }
                    return _SeriesCard(
                      key: ObjectKey(entry),
                      entry: entry,
                      onSeason: (v) => _apply(entry, season: v),
                      onEpisode: (v) => _apply(entry, episode: v),
                      onNextEpisode: () => _apply(entry, episode: entry.episode + 1),
                      onNextSeason: () => _apply(entry, season: entry.season + 1, episode: 1),
                      onEditSeason: () => _askNumber('Temporada', entry.season, (v) => _apply(entry, season: v)),
                      onEditEpisode: () => _askNumber('Capítulo', entry.episode, (v) => _apply(entry, episode: v)),
                      onDelete: () => _confirmDelete(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SeriesCard extends StatelessWidget {
  final SeriesEntry entry;
  final ValueChanged<int> onSeason;
  final ValueChanged<int> onEpisode;
  final VoidCallback onNextEpisode;
  final VoidCallback onNextSeason;
  final VoidCallback onEditSeason;
  final VoidCallback onEditEpisode;
  final VoidCallback onDelete;

  const _SeriesCard({
    super.key,
    required this.entry,
    required this.onSeason,
    required this.onEpisode,
    required this.onNextEpisode,
    required this.onNextSeason,
    required this.onEditSeason,
    required this.onEditEpisode,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Quitar serie',
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  child: _Counter(
                    label: 'TEMPORADA',
                    value: entry.season,
                    onMinus: entry.season > 1 ? () => onSeason(entry.season - 1) : null,
                    onPlus: () => onSeason(entry.season + 1),
                    onTapValue: onEditSeason,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Counter(
                    label: 'CAPÍTULO',
                    value: entry.episode,
                    onMinus: entry.episode > 1 ? () => onEpisode(entry.episode - 1) : null,
                    onPlus: () => onEpisode(entry.episode + 1),
                    onTapValue: onEditEpisode,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: onNextEpisode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Visto · ir al C${entry.episode + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: onNextSeason,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _gold,
                        side: BorderSide(color: _gold.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Nueva T${entry.season + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;
  final VoidCallback onTapValue;

  const _Counter({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    required this.onTapValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundButton(icon: Icons.remove, onPressed: onMinus),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapValue,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Text(
                      '$value',
                      key: ValueKey<int>(value),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              _RoundButton(icon: Icons.add, onPressed: onPlus, highlighted: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool highlighted;

  const _RoundButton({required this.icon, required this.onPressed, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: Material(
        color: highlighted ? _gold.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.08),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 20, color: highlighted ? _gold : Colors.white70),
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _gold : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : _muted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Serie que aún no has empezado: solo título + botón "Empezar".
class _PendingCard extends StatelessWidget {
  final SeriesEntry entry;
  final VoidCallback onStart;
  final VoidCallback onDelete;

  const _PendingCard({
    super.key,
    required this.entry,
    required this.onStart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onStart,
            style: TextButton.styleFrom(
              foregroundColor: _gold,
              backgroundColor: _gold.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Empezar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          IconButton(
            tooltip: 'Quitar serie',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
