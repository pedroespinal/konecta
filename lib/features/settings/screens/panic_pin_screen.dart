import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/repositories/auth_repository.dart';
import '../../../shared/widgets/konecta_footer.dart';

class PanicPinScreen extends ConsumerStatefulWidget {
  const PanicPinScreen({super.key});

  @override
  ConsumerState<PanicPinScreen> createState() => _PanicPinScreenState();
}

class _PanicPinScreenState extends ConsumerState<PanicPinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _hasDecoyPin = false;
  bool _isLoading = true;
  bool _isStep1 = true; // true = enter PIN, false = confirm PIN
  String _enteredPin = '';
  bool _hasError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _checkDecoyPin();
  }

  Future<void> _checkDecoyPin() async {
    final has = await ref.read(authProvider.notifier).hasDecoyPin();
    if (mounted) setState(() { _hasDecoyPin = has; _isLoading = false; });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onStep1Completed(String pin) async {
    setState(() { _enteredPin = pin; _isStep1 = false; _hasError = false; });
    _pinController.clear();
  }

  Future<void> _onStep2Completed(String confirm) async {
    if (confirm != _enteredPin) {
      setState(() {
        _hasError = true;
        _errorMsg = 'Los PINs no coinciden. Intenta de nuevo.';
        _isStep1 = true;
        _enteredPin = '';
      });
      _confirmController.clear();
      _pinController.clear();
      return;
    }

    await ref.read(authProvider.notifier).setupDecoyPin(confirm);
    if (!mounted) return;
    setState(() { _hasDecoyPin = true; });
    _confirmController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN de pánico configurado'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _removeDecoyPin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar PIN de pánico', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('¿Seguro que quieres eliminar el PIN de pánico?',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: KonectaColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).clearDecoyPin();
      if (mounted) setState(() { _hasDecoyPin = false; _isStep1 = true; _enteredPin = ''; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN de pánico eliminado'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pinTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface),
      decoration: BoxDecoration(
        color: isDark ? KonectaColors.darkSurface2 : KonectaColors.lightSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? KonectaColors.darkBorder : KonectaColors.lightBorder),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('PIN de pánico'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: KonectaColors.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Explicación
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: KonectaColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: KonectaColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.crisis_alert_rounded,
                                    color: KonectaColors.primary, size: 32),
                                const SizedBox(height: 10),
                                Text(
                                  'PIN de pánico — Modo decoy',
                                  style: GoogleFonts.inter(
                                      fontSize: 15, fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Si ingresas este PIN en la pantalla de bloqueo, Konecta se abre mostrando una app vacía sin chats ni contactos. Nadie sabrá que hay datos reales.',
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      height: 1.5),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          if (_hasDecoyPin) ...[
                            // Estado: PIN ya configurado
                            Icon(Icons.check_circle_rounded,
                                color: KonectaColors.success, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'PIN de pánico activo',
                              style: GoogleFonts.inter(
                                  fontSize: 18, fontWeight: FontWeight.w700,
                                  color: KonectaColors.success),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Al ingresar el PIN de pánico se mostrará una app vacía.',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _hasDecoyPin = false;
                                  _isStep1 = true;
                                  _enteredPin = '';
                                  _hasError = false;
                                });
                              },
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              label: const Text('Cambiar PIN de pánico'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: KonectaColors.primary,
                                side: BorderSide(color: KonectaColors.primary),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _removeDecoyPin,
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              label: const Text('Eliminar PIN de pánico'),
                              style: TextButton.styleFrom(
                                foregroundColor: KonectaColors.error,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ] else ...[
                            // Configurar nuevo PIN de pánico
                            if (_hasError) ...[
                              Text(
                                _errorMsg,
                                style: GoogleFonts.inter(fontSize: 13, color: KonectaColors.error,
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                            ],

                            Text(
                              _isStep1 ? 'Elige tu PIN de pánico' : 'Confirma el PIN',
                              style: GoogleFonts.inter(
                                  fontSize: 17, fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isStep1
                                  ? 'Debe ser diferente de tu PIN principal'
                                  : 'Ingresa el mismo PIN de nuevo',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 28),

                            if (_isStep1)
                              Pinput(
                                key: const ValueKey('step1'),
                                controller: _pinController,
                                length: 6,
                                autofocus: true,
                                obscureText: true,
                                obscuringCharacter: '●',
                                defaultPinTheme: pinTheme,
                                focusedPinTheme: pinTheme.copyWith(
                                  decoration: pinTheme.decoration!.copyWith(
                                    border: Border.all(color: KonectaColors.primary, width: 2),
                                  ),
                                ),
                                onCompleted: _onStep1Completed,
                              )
                            else
                              Pinput(
                                key: const ValueKey('step2'),
                                controller: _confirmController,
                                length: 6,
                                autofocus: true,
                                obscureText: true,
                                obscuringCharacter: '●',
                                defaultPinTheme: pinTheme,
                                focusedPinTheme: pinTheme.copyWith(
                                  decoration: pinTheme.decoration!.copyWith(
                                    border: Border.all(color: KonectaColors.primary, width: 2),
                                  ),
                                ),
                                onCompleted: _onStep2Completed,
                              ),

                            const SizedBox(height: 20),
                            Text(
                              '⚠️  El PIN de pánico no puede ser igual a tu PIN real',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: KonectaColors.warning,
                                  fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
