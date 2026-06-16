import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart' show getDatabasesPath;
import '../../core/database/models/message_model.dart';

class MediaFile {
  final String localPath;
  final MessageType type;
  final String mimeType;
  final int? durationSeconds;  // audio/video
  final int fileSizeBytes;

  const MediaFile({
    required this.localPath,
    required this.type,
    required this.mimeType,
    required this.fileSizeBytes,
    this.durationSeconds,
  });

  String get fileName => p.basename(localPath);

  String get displaySize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

abstract final class MediaService {
  static final _picker = ImagePicker();

  // ─── Galería ────────────────────────────────────────────────

  static Future<MediaFile?> pickImage({bool camera = false}) async {
    final perm = camera ? Permission.camera : Permission.photos;
    if (!await _checkPerm(perm)) return null;

    final xFile = camera
        ? await _picker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          )
        : await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );

    if (xFile == null) return null;
    final file = File(xFile.path);
    return MediaFile(
      localPath: xFile.path,
      type: MessageType.image,
      mimeType: 'image/jpeg',
      fileSizeBytes: await file.length(),
    );
  }

  static Future<MediaFile?> pickVideo({bool camera = false}) async {
    final perm = camera ? Permission.camera : Permission.videos;
    if (!await _checkPerm(perm)) return null;

    final xFile = camera
        ? await _picker.pickVideo(
            source: ImageSource.camera,
            maxDuration: const Duration(minutes: 5),
          )
        : await _picker.pickVideo(source: ImageSource.gallery);

    if (xFile == null) return null;
    final file = File(xFile.path);
    return MediaFile(
      localPath: xFile.path,
      type: MessageType.video,
      mimeType: 'video/mp4',
      fileSizeBytes: await file.length(),
    );
  }

  // ─── Archivos ───────────────────────────────────────────────

  static Future<MediaFile?> pickFile() async {
    // flutter_file_picker se añade en Fase 6 si se necesita
    // Por ahora retornamos null — placeholder
    return null;
  }

  // ─── Guardar media recibida ─────────────────────────────────

  static Future<String> saveToMediaDir(
    List<int> decryptedBytes, {
    required String filename,
  }) async {
    final base = await getDatabasesPath();
    final dir = Directory(p.join(base, 'media'));
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final dest = File(p.join(dir.path, filename));
    await dest.writeAsBytes(decryptedBytes);
    return dest.path;
  }

  // ─── Permisos ───────────────────────────────────────────────

  static Future<bool> _checkPerm(Permission perm) async {
    var status = await perm.status;
    if (status.isDenied) {
      status = await perm.request();
    }
    return status.isGranted;
  }

  static Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ─── Mostrar selector completo ──────────────────────────────

  static Future<MediaFile?> showPicker(BuildContext context) async {
    MediaFile? result;
    await showModalBottomSheet<MediaFile>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MediaPickerSheet(
        onPick: (f) {
          result = f;
          Navigator.pop(ctx);
        },
      ),
    );
    return result;
  }
}

class _MediaPickerSheet extends StatelessWidget {
  final ValueChanged<MediaFile?> onPick;
  const _MediaPickerSheet({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Item(Icons.camera_alt_rounded, 'Cámara',
                    const Color(0xFFEC4899),
                    () async => onPick(
                        await MediaService.pickImage(camera: true))),
                _Item(Icons.image_rounded, 'Galería',
                    const Color(0xFF8B5CF6),
                    () async => onPick(await MediaService.pickImage())),
                _Item(Icons.videocam_rounded, 'Video',
                    const Color(0xFF06B6D4),
                    () async => onPick(await MediaService.pickVideo())),
                _Item(Icons.insert_drive_file_rounded, 'Archivo',
                    const Color(0xFF10B981),
                    () async => onPick(await MediaService.pickFile())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Item(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
