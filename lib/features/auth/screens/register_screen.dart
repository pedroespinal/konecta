import 'package:country_code_picker/country_code_picker.dart';
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

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  String _countryCode = '+1';
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    if (!_agreeToTerms) return false;
    if (_tabController.index == 0) {
      return _phoneController.text.length >= 7;
    } else {
      final u = _usernameController.text.trim();
      return u.length >= 3 && RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(u);
    }
  }

  void _onContinue() {
    if (!_canContinue) return;
    if (_tabController.index == 0) {
      // Con numero de telefono → OTP
      context.push(AppRoutes.otp, extra: '$_countryCode${_phoneController.text.trim()}');
    } else {
      // Solo nombre de usuario → saltar OTP, ir a perfil
      context.push(AppRoutes.profileSetup, extra: _usernameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface2 = isDark ? KonectaColors.darkSurface2 : KonectaColors.lightSurface2;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      'Elige cómo quieres registrarte',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Tabs: Teléfono / Solo usuario
                    Container(
                      decoration: BoxDecoration(
                        color: surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        onTap: (_) => setState(() {}),
                        indicator: BoxDecoration(
                          color: KonectaColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Número de teléfono'),
                          Tab(text: 'Solo usuario'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contenido según tab
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        if (_tabController.index == 0) {
                          return _PhoneInput(
                            controller: _phoneController,
                            countryCode: _countryCode,
                            onCountryChanged: (code) =>
                                setState(() => _countryCode = code),
                            onChanged: (_) => setState(() {}),
                          );
                        } else {
                          return _UsernameInput(
                            controller: _usernameController,
                            onChanged: (_) => setState(() {}),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Terminos y condiciones
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

                    const SizedBox(height: 8),

                    // Nota de privacidad
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
                              'Konecta no recopila ni vende tus datos. Tu número '
                              'nunca se comparte con terceros.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: KonectaColors.accent,
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

class _PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onChanged;

  const _PhoneInput({
    required this.controller,
    required this.countryCode,
    required this.onCountryChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Número de teléfono',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country code picker
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? KonectaColors.darkSurface2
                    : KonectaColors.lightSurface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CountryCodePicker(
                onChanged: (c) => onCountryChanged(c.dialCode ?? '+1'),
                initialSelection: 'US',
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
                textStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Número de teléfono',
                  prefixText: '$countryCode ',
                  prefixStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: KonectaColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Te enviaremos un código de verificación por SMS.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _UsernameInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _UsernameInput({required this.controller, required this.onChanged});

  bool _isValid(String v) =>
      v.length >= 3 && RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(v);

  @override
  Widget build(BuildContext context) {
    final val = controller.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          controller: controller,
          onChanged: onChanged,
          autocorrect: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.]')),
          ],
          style: GoogleFonts.inter(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'ej: pedro.espinal',
            prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
            suffixIcon: val.isNotEmpty
                ? Icon(
                    _isValid(val)
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: _isValid(val)
                        ? KonectaColors.accent
                        : KonectaColors.error,
                    size: 20,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Solo letras, números, puntos y guiones bajos. Mínimo 3 caracteres.\n'
          'Sin número de teléfono — mayor privacidad.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
