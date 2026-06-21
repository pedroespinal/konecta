import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/security/signature_verifier.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../shared/widgets/konecta_footer.dart';
import '../../shared/widgets/konecta_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _pulseScale = Tween<double>(begin: 0.85, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.55, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _initialize();
  }

  Future<void> _initialize() async {
    _controller.forward();

    // 1. Verificar firma criptografica de autoria (invisible para el usuario)
    await SignatureVerifier.verifyOnStartup();

    // 2. Verificar si hay sesion activa
    await ref.read(authProvider.notifier).checkSession();

    // 3. Pausa minima para que la animacion se vea completa
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    // 4. Redirigir segun estado de sesion
    final auth = ref.read(authProvider);
    switch (auth.status) {
      case AuthStatus.authenticated:
        context.go(AppRoutes.home);
      case AuthStatus.pinRequired:
        context.go(AppRoutes.lock);
      case AuthStatus.unauthenticated:
      case AuthStatus.unknown:
        context.go(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (_, __) => Opacity(
                                opacity: _pulseOpacity.value,
                                child: Transform.scale(
                                  scale: _pulseScale.value,
                                  child: Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: KonectaColors.primary,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const KonectaLogo(size: 96),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [KonectaColors.primary, KonectaColors.secondary],
                          ).createShader(bounds),
                          child: const Text(
                            'Konecta',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mensajería segura y privada',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: KonectaColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
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
