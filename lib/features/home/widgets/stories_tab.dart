import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class StoriesTab extends StatelessWidget {
  const StoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                _MyStoryTile(),
                const SizedBox(height: 20),
                Text('Estados recientes', style: Theme.of(context).textTheme.labelMedium),
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
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: KonectaColors.primary,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: KonectaColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
              child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
      title: const Text('Agregar estado'),
      subtitle: const Text('Toca para agregar'),
      onTap: () {},
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
        width: 52, height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: KonectaColors.primary, width: 2.5),
        ),
        padding: const EdgeInsets.all(2),
        child: CircleAvatar(
          backgroundColor: KonectaColors.secondary.withValues(alpha: 0.2),
          child: Text(
            _names[index][0],
            style: const TextStyle(color: KonectaColors.secondary, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      title: Text(_names[index]),
      subtitle: Text(_times[index]),
      onTap: () {},
    );
  }
}
