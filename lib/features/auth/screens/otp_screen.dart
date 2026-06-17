import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/konecta_footer.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  int _secondsLeft = 60;
  Timer? _timer;
  bool _hasError = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify(String pin) async {
    if (pin.length != 6) return;
    setState(() {
      _isVerifying = true;
      _hasError = false;
    });
    // TODO Fase 3: verificar OTP real con el servidor
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Modo demo: cualquier código de 6 dígitos es válido
    // Fase 3 conectará un servidor SMS real
    if (pin.length == 6) {
      context.pushReplacement(AppRoutes.profileSetup, extra: widget.phoneNumber);
    } else {
      setState(() {
        _hasError = true;
        _isVerifying = false;
      });
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: isDark ? KonectaColors.darkSurface2 : KonectaColors.lightSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? KonectaColors.darkBorder : KonectaColors.lightBorder,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: KonectaColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sms_rounded,
                        color: KonectaColors.primary,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Código de verificación',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ingresa el código enviado a\n${widget.phoneNumber}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: KonectaColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: KonectaColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: KonectaColors.accent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Versión demo — usa cualquier código de 6 dígitos',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: KonectaColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // PIN input
                    Pinput(
                      controller: _pinController,
                      focusNode: _focusNode,
                      length: 6,
                      autofocus: true,
                      defaultPinTheme: defaultTheme,
                      focusedPinTheme: defaultTheme.copyWith(
                        decoration: defaultTheme.decoration!.copyWith(
                          border: Border.all(
                            color: KonectaColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      errorPinTheme: defaultTheme.copyWith(
                        decoration: defaultTheme.decoration!.copyWith(
                          border: Border.all(
                            color: KonectaColors.error,
                            width: 2,
                          ),
                        ),
                      ),
                      forceErrorState: _hasError,
                      onCompleted: _verify,
                    ),

                    if (_hasError) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Código incorrecto. Intenta de nuevo.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: KonectaColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    if (_isVerifying)
                      const CircularProgressIndicator(
                        color: KonectaColors.primary,
                        strokeWidth: 2.5,
                      )
                    else if (_secondsLeft > 0)
                      Text(
                        'Reenviar código en $_secondsLeft s',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: _startTimer,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Reenviar código'),
                      ),

                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: KonectaColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline_rounded,
                              color: KonectaColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'El código solo sirve para verificar tu número. Konecta no guarda tu teléfono en ningún servidor.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: KonectaColors.primary,
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
            const KonectaFooter(),
          ],
        ),
      ),
    );
  }
}
