import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/repositories/auth_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
  }

  Future<void> _setTheme(ThemeMode mode) async {
    ref.read(themeModeProvider.notifier).state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kc_theme_mode', mode.index);
  }

  Future<void> _setLocale(Locale? locale) async {
    ref.read(localeProvider.notifier).state = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove('kc_language_code');
    } else {
      await prefs.setString('kc_language_code', locale.languageCode);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: KonectaColors.error),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).deleteAccount();
      if (mounted) context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final profile = ref.watch(authProvider).profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // ── Perfil ────────────────────────────────────────────────
          if (profile != null) ...[
            _SectionHeader(text: l10n.profile),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? KonectaColors.darkSurface : KonectaColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? KonectaColors.darkBorder : KonectaColors.lightBorder,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: KonectaColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      profile.displayName.isNotEmpty
                          ? profile.displayName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: KonectaColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (profile.phone != null && profile.phone!.isNotEmpty)
                          Text(
                            profile.phone!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Apariencia ────────────────────────────────────────────
          _SectionHeader(text: l10n.appearance),
          _SettingsCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Text(
                    l10n.chooseTheme,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_rounded, size: 18),
                        label: Text(l10n.darkMode,
                            style: GoogleFonts.inter(fontSize: 13)),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto_rounded, size: 18),
                        label: Text(l10n.systemMode,
                            style: GoogleFonts.inter(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode_rounded, size: 18),
                        label: Text(l10n.lightMode,
                            style: GoogleFonts.inter(fontSize: 13)),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (s) => _setTheme(s.first),
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Idioma ───────────────────────────────────────────────
          _SettingsCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Text(
                    l10n.chooseLanguage,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'es',
                        icon: const Text('🇪🇸', style: TextStyle(fontSize: 18)),
                        label: Text('Español',
                            style: GoogleFonts.inter(fontSize: 13)),
                      ),
                      ButtonSegment(
                        value: 'en',
                        icon: const Text('🇺🇸', style: TextStyle(fontSize: 18)),
                        label: Text('English',
                            style: GoogleFonts.inter(fontSize: 13)),
                      ),
                    ],
                    selected: {locale?.languageCode ?? 'es'},
                    onSelectionChanged: (s) =>
                        _setLocale(Locale(s.first)),
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Seguridad ─────────────────────────────────────────────
          _SectionHeader(text: l10n.security),
          _SettingsCard(
            isDark: isDark,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.lock_rounded,
                  iconColor: KonectaColors.primary,
                  title: l10n.changePinTitle,
                  subtitle: 'Actualiza tu PIN de desbloqueo',
                  onTap: () => context.push(AppRoutes.pinSetup),
                ),
                _Divider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.fingerprint_rounded,
                  iconColor: KonectaColors.secondary,
                  title: l10n.biometricUnlock,
                  subtitle: 'Huella digital o reconocimiento facial',
                  onTap: () => context.push(AppRoutes.biometricSetup),
                ),
              ],
            ),
          ),

          // ── Cuenta ────────────────────────────────────────────────
          _SectionHeader(text: l10n.accountSection),
          _SettingsCard(
            isDark: isDark,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: KonectaColors.warning,
                  title: l10n.signOut,
                  subtitle: 'Cierra sesión sin borrar tus datos',
                  onTap: () {
                    ref.read(authProvider.notifier).signOut();
                    context.go(AppRoutes.lock);
                  },
                ),
                _Divider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: KonectaColors.error,
                  title: l10n.deleteAccount,
                  subtitle: 'Elimina tu cuenta y todas tus claves',
                  onTap: _confirmDeleteAccount,
                  titleColor: KonectaColors.error,
                ),
              ],
            ),
          ),

          // ── Acerca de ─────────────────────────────────────────────
          _SectionHeader(text: l10n.about),
          _SettingsCard(
            isDark: isDark,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: KonectaColors.accent,
                  title: l10n.version,
                  subtitle: _version.isEmpty ? '...' : _version,
                ),
                _Divider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.code_rounded,
                  iconColor: KonectaColors.primary,
                  title: l10n.developer,
                  subtitle: 'Pedro Espinal — Konecta 2026',
                ),
                _Divider(isDark: isDark),
                _SettingsTile(
                  icon: Icons.shield_rounded,
                  iconColor: KonectaColors.secondary,
                  title: 'Cifrado',
                  subtitle: 'Signal Protocol — E2E — AES-256-GCM',
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Text(
              'Konecta — Todos los derechos reservados 2026\nPedro Espinal',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: KonectaColors.primary,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _SettingsCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? KonectaColors.darkSurface : KonectaColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? KonectaColors.darkBorder : KonectaColors.lightBorder,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: 68,
      color: isDark ? KonectaColors.darkDivider : KonectaColors.lightDivider,
    );
  }
}
