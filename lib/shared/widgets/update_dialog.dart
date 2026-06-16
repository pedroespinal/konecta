import 'package:flutter/material.dart';
import '../../core/services/update_checker.dart';
import '../../core/constants/app_version.dart';

/// Muestra el popup de actualización.
/// [forceUpdate] = true → botón "Ahora" sin opción de cerrar.
class UpdateDialog extends StatelessWidget {
  final UpdateInfo info;

  const UpdateDialog({super.key, required this.info});

  /// Muestra el diálogo y retorna true si el usuario aceptó actualizar.
  static Future<bool> show(BuildContext context, UpdateInfo info) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: !info.forceUpdate,
          builder: (_) => UpdateDialog(info: info),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final colors = theme.colorScheme;

    return PopScope(
      // Bloquear cierre con botón atrás si es actualización forzada
      canPop: !info.forceUpdate,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con gradiente
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.system_update_rounded,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    info.forceUpdate
                        ? 'Actualización requerida'
                        : '¡Nueva versión disponible!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Versiones
                  Row(
                    children: [
                      _VersionChip(
                        label: 'Actual',
                        version: AppVersion.version,
                        color: colors.outline,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded, size: 18),
                      ),
                      _VersionChip(
                        label: 'Nueva',
                        version: info.latestVersion,
                        color: colors.primary,
                      ),
                    ],
                  ),

                  if (info.releaseNotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Novedades:',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      info.releaseNotes,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  if (info.forceUpdate) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: colors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esta versión ya no es compatible. '
                              'Debes actualizar para continuar.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Botones
                  Row(
                    children: [
                      if (!info.forceUpdate) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Ahora no'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        flex: info.forceUpdate ? 1 : 1,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Actualizar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  final String label;
  final String version;
  final Color color;

  const _VersionChip({
    required this.label,
    required this.version,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                )),
        Text(
          'v$version',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
