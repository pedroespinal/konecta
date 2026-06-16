import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/konecta_footer.dart';
import '../../../shared/widgets/konecta_logo.dart';
import '../repositories/auth_repository.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pinController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _hasError = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    // Intentar biometria automaticamente al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final profile = ref.read(authProvider).profile;
    if (profile?.hasBiometrics != true) return;
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Desbloquear Konecta',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (ok && mounted) {
        ref.read(authProvider.notifier).onBiometricSuccess();
      }
    } catch (_) {}
  }

  Future<void> _onPinCompleted(String pin) async {
    setState(() {
      _isVerifying = true;
      _hasError = false;
    });
    final valid = await ref.read(authProvider.notifier).verifyPin(pin);
    if (!mounted) return;
    if (!valid) {
      setState(() {
        _hasError = true;
        _isVerifying = false;
      });
      _pinController.clear();
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pinTheme = PinTheme(
      width: 56,
      height: 64,
      textStyle: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: isDark ? KonectaColors.darkSurface2 : KonectaColors.lightSurface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? KonectaColors.darkBorder : KonectaColors.lightBorder,
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const KonectaLogo(size: 64, showText: true),
                      const SizedBox(height: 32),

                      // Avatar del usuario
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: KonectaColors.primary.withValues(alpha: 0.15),
                        child: Text(
                          (profile?.displayName.isNotEmpty == true)
                              ? profile!.displayName[0].toUpperCase()
                              : 'K',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: KonectaColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile?.displayName ?? 'Konecta',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ingresa tu PIN para continuar',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 36),

                      if (_hasError) ...[
                        Text(
                          'PIN incorrecto. Intenta de nuevo.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: KonectaColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      _isVerifying
                          ? const CircularProgressIndicator(
                              color: KonectaColors.primary, strokeWidth: 2.5)
                          : Pinput(
                              controller: _pinController,
                              length: 6,
                              autofocus: true,
                              obscureText: true,
                              obscuringCharacter: '●',
                              defaultPinTheme: pinTheme,
                              focusedPinTheme: pinTheme.copyWith(
                                decoration: pinTheme.decoration!.copyWith(
                                  border: Border.all(
                                    color: KonectaColors.primary,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              onCompleted: _onPinCompleted,
                            ),

                      const SizedBox(height: 28),

                      if (profile?.hasBiometrics == true)
                        IconButton.filled(
                          onPressed: _tryBiometric,
                          icon: const Icon(Icons.fingerprint_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                KonectaColors.primary.withValues(alpha: 0.12),
                            foregroundColor: KonectaColors.primary,
                            minimumSize: const Size(56, 56),
                          ),
                          tooltip: 'Usar biometría',
                        ),
                    ],
                  ),
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
