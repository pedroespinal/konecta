import 'package:go_router/go_router.dart';
import '../../core/database/models/chat_model.dart';
import '../../features/auth/screens/biometric_setup_screen.dart';
import '../../features/auth/screens/lock_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/pin_setup_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/calls/screens/call_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/chat/screens/new_chat_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/splash/splash_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String register = '/register';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
  static const String pinSetup = '/pin-setup';
  static const String biometricSetup = '/biometric-setup';
  static const String lock = '/lock';
  static const String home = '/home';
  static const String newChat = '/new-chat';
  static const String chat = '/chat';
  static const String call = '/call';
  static const String settings = '/settings';
  static const String about = '/settings/about';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: SplashScreen()),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      builder: (context, state) =>
          OtpScreen(phoneNumber: state.extra as String? ?? ''),
    ),
    GoRoute(
      path: AppRoutes.profileSetup,
      builder: (context, state) =>
          ProfileSetupScreen(identifier: state.extra as String? ?? ''),
    ),
    GoRoute(
      path: AppRoutes.pinSetup,
      builder: (context, state) => const PinSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.biometricSetup,
      builder: (context, state) => const BiometricSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.lock,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LockScreen()),
    ),
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: HomeScreen()),
    ),
    GoRoute(
      path: AppRoutes.newChat,
      builder: (context, state) => const NewChatScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.chat}/:id',
      builder: (context, state) {
        final chat = state.extra as ChatModel?;
        if (chat == null) return const HomeScreen();
        return ChatScreen(chat: chat);
      },
    ),
    GoRoute(
      path: AppRoutes.call,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>?;
        return CallScreen(
          peerId: args?['peerId'] as String? ?? '',
          peerName: args?['peerName'] as String? ?? '',
          isVideo: args?['isVideo'] as bool? ?? false,
          isOutgoing: args?['isOutgoing'] as bool? ?? true,
        );
      },
    ),
  ],
);
