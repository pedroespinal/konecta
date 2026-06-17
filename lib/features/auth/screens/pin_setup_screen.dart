import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/konecta_footer.dart';
import '../repositories/auth_repository.dart';

enum _PinStep { enter, confirm }

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pinController = TextEditingController();
  _PinStep _step = _PinStep.enter;
  String _firstPin = '';
  bool _hasError = false;
  bool _isSaving = false;

  void _onPinCompleted(String pin) {
    if (_step == _PinStep.enter) {
      setState(() {
        _firstPin = pin;
        _step = _PinStep.confirm;
        _hasError = false;
      });
      _pinController.clear();
    } else {
      if (pin == _firstPin) {
        _savePin(pin);
      } else {
        setState(() {
          _hasError = true;
          _step = _PinStep.enter;
          _firstPin = '';
        });
        _pinController.clear();
      }
    }
  }

  Future<void> _savePin(String pin) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).setupPin(pin);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.biometricSetup);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el PIN. Intenta de nuevo.'),
          backgroundColor: KonectaColors.error,
        ),
      );
    }
  }

  void _skip() => context.go(AppRoutes.home);

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pinTheme = PinTheme(
      width: 60,
      height: 68,
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

    return PopScope(
      canPop: false,
      child: Scaffold(
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
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Icono animado
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_step),
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _step == _PinStep.enter
                                ? [KonectaColors.primary, KonectaColors.primaryLight]
                                : [KonectaColors.accent, KonectaColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (_step == _PinStep.enter
                                      ? KonectaColors.primary
                                      : KonectaColors.accent)
                                  .withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _step == _PinStep.enter
                              ? Icons.lock_rounded
                              : Icons.check_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        key: ValueKey(_step),
                        _step == _PinStep.enter
                            ? 'Elige un PIN de seguridad'
                            : 'Confirma tu PIN',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _step == _PinStep.enter
                          ? 'Este PIN desbloquea Konecta en este dispositivo.\n'
                              'Diferente de tu contraseña de cuenta.'
                          : 'Ingresa el mismo PIN para confirmar.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),

                    if (_hasError) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: KonectaColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_rounded,
                                color: KonectaColors.error, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Los PINs no coinciden. Intenta de nuevo.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: KonectaColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _isSaving
                        ? const CircularProgressIndicator(
                            color: KonectaColors.primary)
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

                    const SizedBox(height: 24),

                    // Opción de acceder sin PIN
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _skip,
                        icon: const Icon(Icons.no_encryption_rounded, size: 18),
                        label: Text(
                          'Acceder sin PIN',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Indicador de progreso de los pasos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StepDot(active: true, done: _step == _PinStep.confirm),
                        const SizedBox(width: 8),
                        _StepDot(active: _step == _PinStep.confirm, done: false),
                      ],
                    ),

                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: KonectaColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: KonectaColors.warning.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: KonectaColors.warning, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Si olvidas el PIN, podrás restablecerlo con '
                              'tu copia de seguridad cifrada.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: KonectaColors.warning,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const KonectaFooter(),
          ],
        ),
      ),
    ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  const _StepDot({required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: done ? 28 : (active ? 32 : 10),
      height: 10,
      decoration: BoxDecoration(
        color: active || done
            ? KonectaColors.primary
            : KonectaColors.primary.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
