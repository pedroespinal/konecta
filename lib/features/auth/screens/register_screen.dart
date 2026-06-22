import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/konecta_footer.dart';
import '../../../shared/widgets/konecta_logo.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  bool get _isUsernameValid {
    final u = _usernameController.text.trim();
    return u.length >= 3 && RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(u);
  }

  bool get _canContinue => _agreeToTerms && _isUsernameValid;

  void _onContinue() {
    if (!_canContinue) return;
    context.push(AppRoutes.profileSetup,
        extra: _usernameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final val = _usernameController.text.trim();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  const KonectaLogo(size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Konecta',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: KonectaColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear cuenta',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Elige tu nombre de usuario',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),

                    Text(
                      'Nombre de usuario',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      onChanged: (_) => setState(() {}),
                      autocorrect: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9_.]')),
                      ],
                      style: GoogleFonts.inter(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'ej: pedro.espinal',
                        prefixIcon: const Icon(
                            Icons.alternate_email_rounded,
                            size: 20),
                        suffixIcon: val.isNotEmpty
                            ? Icon(
                                _isUsernameValid
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                color: _isUsernameValid
                                    ? KonectaColors.accent
                                    : KonectaColors.error,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Solo letras, números, puntos y guiones bajos. Mínimo 3 caracteres.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Privacidad
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KonectaColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: KonectaColors.accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            color: KonectaColors.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sin número de teléfono — mayor privacidad. '
                              'Konecta no recopila ni vende tus datos.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: KonectaColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Términos
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreeToTerms,
                            onChanged: (v) =>
                                setState(() => _agreeToTerms = v ?? false),
                            activeColor: KonectaColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              children: const [
                                TextSpan(text: 'Acepto los '),
                                TextSpan(
                                  text: 'Términos de servicio',
                                  style: TextStyle(
                                    color: KonectaColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: ' y la '),
                                TextSpan(
                                  text: 'Política de privacidad',
                                  style: TextStyle(
                                    color: KonectaColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: ' de Konecta.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canContinue ? _onContinue : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Continuar',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.inter(fontSize: 14),
                            children: [
                              TextSpan(
                                text: '¿Ya tienes cuenta? ',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              const TextSpan(
                                text: 'Iniciar sesión',
                                style: TextStyle(
                                  color: KonectaColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
}
