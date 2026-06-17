import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

const _kMyStatuses = 'kc_my_statuses';

class StoriesTab extends StatefulWidget {
  const StoriesTab({super.key});

  @override
  State<StoriesTab> createState() => _StoriesTabState();
}

class _StoriesTabState extends State<StoriesTab> {
  List<Map<String, dynamic>> _myStatuses = [];

  @override
  void initState() {
    super.initState();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kMyStatuses) ?? [];
    if (mounted) {
      setState(() {
        _myStatuses = raw
            .map((s) => jsonDecode(s) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  Future<void> _addStatus(String text) async {
    final newStatus = <String, dynamic>{
      'text': text,
      'time': DateTime.now().millisecondsSinceEpoch,
    };
    final updated = [newStatus, ..._myStatuses];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kMyStatuses, updated.map((s) => jsonEncode(s)).toList());
    if (mounted) setState(() => _myStatuses = updated);
  }

  Future<void> _deleteStatus(int index) async {
    final updated = [..._myStatuses]..removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kMyStatuses, updated.map((s) => jsonEncode(s)).toList());
    if (mounted) setState(() => _myStatuses = updated);
  }

  void _showAddStatusDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nuevo estado'),
        content: TextField(
          controller: controller,
          maxLength: 139,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '¿Qué está pasando?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (_) => _submit(ctx, controller),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => _submit(ctx, controller),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext ctx, TextEditingController c) {
    final text = c.text.trim();
    if (text.isNotEmpty) {
      Navigator.pop(ctx);
      _addStatus(text);
    }
  }

  void _showMyStatus(int index) {
    final status = _myStatuses[index];
    final text = status['text'] as String;
    final time = DateTime.fromMillisecondsSinceEpoch(status['time'] as int);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mi estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KonectaColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(time),
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteStatus(index);
            },
            style: TextButton.styleFrom(foregroundColor: KonectaColors.error),
            child: const Text('Eliminar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} hora${diff.inHours > 1 ? 's' : ''}';
    return 'Hace ${diff.inDays} día${diff.inDays > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: Text(l10n.navStories),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mi estado', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 12),
                _MyStoryTile(
                  statuses: _myStatuses,
                  onAddTap: _showAddStatusDialog,
                  onStatusTap: _showMyStatus,
                ),
                if (_myStatuses.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Preview del estado más reciente
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? KonectaColors.darkSurface2
                          : KonectaColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? KonectaColors.darkBorder
                            : KonectaColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _myStatuses.first['text'] as String,
                            style: GoogleFonts.inter(fontSize: 13, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(DateTime.fromMillisecondsSinceEpoch(
                              _myStatuses.first['time'] as int)),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text('Estados recientes',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _StoryListItem(index: index),
            childCount: 8,
          ),
        ),
      ],
    );
  }
}

class _MyStoryTile extends StatelessWidget {
  final List<Map<String, dynamic>> statuses;
  final VoidCallback onAddTap;
  final ValueChanged<int> onStatusTap;

  const _MyStoryTile({
    required this.statuses,
    required this.onAddTap,
    required this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasStatus = statuses.isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: hasStatus
                  ? Border.all(color: KonectaColors.primary, width: 2.5)
                  : null,
              color: KonectaColors.primary.withValues(alpha: 0.15),
            ),
            child: const Center(
              child: Icon(Icons.person_rounded,
                  color: KonectaColors.primary, size: 28),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onAddTap,
              child: Container(
                decoration: BoxDecoration(
                  color: KonectaColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2),
                ),
                child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      title: Text(hasStatus ? 'Mi estado' : 'Agregar estado'),
      subtitle: Text(hasStatus
          ? '${statuses.length} estado${statuses.length > 1 ? 's' : ''} publicado${statuses.length > 1 ? 's' : ''}'
          : 'Toca + para agregar'),
      onTap: hasStatus ? () => onStatusTap(0) : onAddTap,
    );
  }
}

class _StoryListItem extends StatelessWidget {
  final int index;
  const _StoryListItem({required this.index});
  static const _names = [
    'Maria Garcia', 'Carlos Lopez', 'Sofia Chen', 'Laura Martinez',
    'Diego Morales', 'Roberto Silva', 'Valentina Ruiz', 'Juan Perez',
  ];
  static const _times = [
    'Hace 5 min', 'Hace 23 min', 'Hace 1 hora', 'Hace 2 horas',
    'Hace 3 horas', 'Hace 5 horas', 'Hace 8 horas', 'Hace 12 horas',
  ];

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: KonectaColors.primary, width: 2.5),
        ),
        padding: const EdgeInsets.all(2),
        child: CircleAvatar(
          backgroundColor: KonectaColors.secondary.withValues(alpha: 0.2),
          child: Text(
            _names[index][0],
            style: const TextStyle(
                color: KonectaColors.secondary, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      title: Text(_names[index]),
      subtitle: Text(_times[index]),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ver estado de ${_names[index]} — próximamente'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}
