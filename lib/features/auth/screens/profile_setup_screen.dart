import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/konecta_footer.dart';
import '../repositories/auth_repository.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final String identifier; // telefono o username
  const ProfileSetupScreen({super.key, required this.identifier});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String? _avatarPath;
  bool _isLoading = false;

  bool get _canContinue =>
      _nameController.text.trim().length >= 2 && !_isLoading;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _avatarPath = image.path);
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _avatarPath = image.path);
    }
  }

  Future<void> _continue() async {
    if (!_canContinue) return;
    setState(() => _isLoading = true);

    try {
      // Genera claves Signal Protocol y crea perfil
      await ref.read(authProvider.notifier).register(
            displayName: _nameController.text.trim(),
            phone: widget.identifier.startsWith('+') ? widget.identifier : null,
            avatarPath: _avatarPath,
          );

      if (mounted) context.pushReplacement(AppRoutes.pinSetup);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear perfil: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu perfil')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Configura tu perfil',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tu nombre y foto son visibles para tus contactos.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Avatar
                    GestureDetector(
                      onTap: _showAvatarOptions,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundColor: KonectaColors.primary
                                .withValues(alpha: 0.15),
                            backgroundImage: _avatarPath != null
                                ? FileImage(File(_avatarPath!))
                                : null,
                            child: _avatarPath == null
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 56,
                                    color: KonectaColors.primary
                                        .withValues(alpha: 0.7),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: KonectaColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Nombre
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.inter(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Nombre completo *',
                        hintText: 'Ej: Pedro Espinal',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        counterText: '${_nameController.text.length}/50',
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    TextField(
                      controller: _bioController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.inter(fontSize: 16),
                      maxLines: 3,
                      maxLength: 140,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: 'Cuéntale algo a tus contactos...',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Aviso de generacion de claves
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: KonectaColors.secondary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: KonectaColors.secondary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.vpn_key_rounded,
                            color: KonectaColors.secondary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Al continuar, Konecta generará tus claves de '
                              'cifrado únicas directamente en este dispositivo. '
                              'Nadie más puede leer tus mensajes.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: KonectaColors.secondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canContinue ? _continue : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Crear cuenta y generar claves',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const KonectaFooter(),
          ],
        ),
      ),
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: KonectaColors.primary),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: KonectaColors.secondary),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              if (_avatarPath != null)
                ListTile(
                  leading:
                      const Icon(Icons.delete_rounded, color: KonectaColors.error),
                  title: const Text('Eliminar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _avatarPath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
