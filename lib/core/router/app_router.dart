import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/email_auth_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/network_error_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';

/// 앱 전체 라우트 경로 상수
abstract class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const loginEmail = '/login/email';
  static const loginEmailForgot = '/login/email/forgot';
  static const onboarding = '/onboarding';
  static const calendar = '/calendar';
  static const networkError = '/error';
}

/// authStateProvider 변경 시 GoRouter에 리프레시 신호를 보내는 노티파이어
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // authStateProvider가 바뀔 때마다 GoRouter의 redirect를 재평가
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final location = state.matchedLocation;

    // 로딩 중 → 스플래시 유지
    if (authState.isLoading) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

    // 에러 (재시도 3회 모두 실패) → 네트워크 에러 페이지
    if (authState.hasError) {
      return location == AppRoutes.networkError ? null : AppRoutes.networkError;
    }

    final user = authState.valueOrNull;

    // 미로그인 → 로그인 페이지 (이미 로그인 경로면 유지)
    if (user == null) {
      if (location.startsWith(AppRoutes.login)) return null;
      return AppRoutes.login;
    }

    // 로그인 + 온보딩 미완료 → 온보딩
    if (!user.isOnboarded) {
      if (location == AppRoutes.onboarding) return null;
      return AppRoutes.onboarding;
    }

    // 로그인 + 온보딩 완료 → 인증 관련 경로에 있으면 캘린더로
    if (location == AppRoutes.splash ||
        location.startsWith(AppRoutes.login) ||
        location == AppRoutes.onboarding) {
      return AppRoutes.calendar;
    }

    return null;
  }
}

/// 앱 전체 라우터 Provider
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginPage(),
        routes: [
          GoRoute(
            path: 'email',
            builder: (_, _) => const EmailAuthPage(),
            routes: [
              GoRoute(
                path: 'forgot',
                builder: (_, _) => const ForgotPasswordPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        builder: (_, _) => const CalendarPage(),
      ),
      GoRoute(
        path: AppRoutes.networkError,
        builder: (_, _) => const NetworkErrorPage(),
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});
