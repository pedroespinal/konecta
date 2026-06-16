import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/konecta_footer.dart';
import '../repositories/auth_repository.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isChecking = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck || !mounted) return;
    final types = await _localAuth.getAvailableBiometrics();
    setState(() => _availableBiometrics = types);
  }

  bool get _hasBiometrics => _availableBiometrics.isNotEmpty;
  bool get _hasFace =>
      _availableBiometrics.contains(BiometricType.face) ||
      _availableBiometrics.contains(BiometricType.iris);
  bool get _hasFingerprint =>
      _availableBiometrics.contains(BiometricType.fingerprint) ||
      _availableBiometrics.contains(BiometricType.strong) ||
      _availableBiometrics.contains(BiometricType.weak);

  Future<void> _enableBiometrics() async {
    setState(() => _isChecking = true);
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Autenticación de prueba para activar Konecta',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (!mounted) return;
      if (authenticated) {
        await ref.read(authProvider.notifier).setBiometricsEnabled(true);
        if (!mounted) return;
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al configurar biometría: $e'),
            backgroundColor: KonectaColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _skip() => context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    final biometricIcon = _hasFace
        ? Icons.face_rounded
        : _hasFingerprint
            ? Icons.fingerprint_rounded
            : Icons.security_rounded;

    final biometricName =
        _hasFace ? 'Reconocimiento facial' : 'Huella digital';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(
              'Omitir',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [KonectaColors.secondary, KonectaColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: KonectaColors.secondary.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(biometricIcon, color: Colors.white, size: 56),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      _hasBiometrics
                          ? 'Activa $biometricName'
                          : 'Sin biometría disponible',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasBiometrics
                          ? 'Desbloquea Konecta de forma rápida y segura\n'
                              'usando $biometricName, sin necesidad de PIN.'
                          : 'Este dispositivo no tiene biometría configurada.\n'
                              'Usarás tu PIN para desbloquear Konecta.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),

                    if (_hasBiometrics) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isChecking ? null : _enableBiometrics,
                          icon: _isChecking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(biometricIcon),
                          label: Text(
                            _isChecking
                                ? 'Verificando...'
                                : 'Activar $biometricName',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _skip,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _hasBiometrics ? 'Usar solo PIN' : 'Continuar con PIN',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Beneficios
                    if (_hasBiometrics)
                      _BenefitRow(
                        icon: Icons.bolt_rounded,
                        color: KonectaColors.secondary,
                        text: 'Más rápido que escribir el PIN',
                      ),
                    _BenefitRow(
                      icon: Icons.shield_rounded,
                      color: KonectaColors.accent,
                      text: 'Nadie más puede desbloquear tu Konecta',
                    ),
                    _BenefitRow(
                      icon: Icons.no_photography_rounded,
                      color: KonectaColors.primary,
                      text: 'Biometría procesada solo en el dispositivo',
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
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _BenefitRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
