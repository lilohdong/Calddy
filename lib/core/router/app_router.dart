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
import '../../features/appointment/presentation/pages/appointment_create_page.dart';
import '../../features/appointment/presentation/pages/appointment_detail_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/calendar/presentation/pages/drawing_page.dart';
import '../../features/calendar/presentation/pages/event_create_page.dart';
import '../../features/calendar/presentation/pages/event_detail_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/feed/presentation/pages/post_create_page.dart';
import '../../features/feed/presentation/pages/post_detail_page.dart';
import '../../features/friend/presentation/pages/friend_calendar_page.dart';
import '../../features/friend/presentation/pages/friends_page.dart';
import '../../features/friend/presentation/pages/merge_calendar_page.dart';
import '../../features/map/presentation/pages/place_picker_page.dart';
import '../../features/notification/presentation/pages/notifications_page.dart';
import '../../features/user/presentation/pages/edit_profile_page.dart';
import '../../features/user/presentation/pages/profile_page.dart';
import '../../features/user/presentation/pages/settings_page.dart';
import 'app_routes.dart';
import 'main_shell.dart';

/// authStateProvider 변경 시 GoRouter에 리프레시 신호를 보내는 노티파이어
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
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

    // 로그인 + 온보딩 완료 → 인증 경로에 있으면 홈으로
    if (location == AppRoutes.splash ||
        location.startsWith(AppRoutes.login) ||
        location == AppRoutes.onboarding) {
      return AppRoutes.home;
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
      // ── Auth 경로 ────────────────────────────────────────────
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
        path: AppRoutes.networkError,
        builder: (_, _) => const NetworkErrorPage(),
      ),

      // ── Shell (하단 탭 네비게이션) ───────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const CalendarPage(),
            routes: [
              GoRoute(
                path: 'event/create',
                builder: (_, _) => const EventCreatePage(),
              ),
              GoRoute(
                path: 'event/:eventId',
                builder: (_, s) => EventDetailPage(
                  eventId: s.pathParameters['eventId']!,
                ),
              ),
              GoRoute(
                path: 'drawing/:date',
                builder: (_, s) => DrawingPage(
                  date: s.pathParameters['date']!,
                ),
              ),
              GoRoute(
                path: 'appointment/create',
                builder: (_, _) => const AppointmentCreatePage(),
              ),
              GoRoute(
                path: 'appointment/:appointmentId',
                builder: (_, s) => AppointmentDetailPage(
                  appointmentId: s.pathParameters['appointmentId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.feed,
            builder: (_, _) => const FeedPage(),
            routes: [
              GoRoute(
                path: 'post/create',
                builder: (_, _) => const PostCreatePage(),
              ),
              GoRoute(
                path: 'post/:postId',
                builder: (_, s) => PostDetailPage(
                  postId: s.pathParameters['postId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.friends,
            builder: (_, _) => const FriendsPage(),
            routes: [
              GoRoute(
                path: ':friendId/calendar',
                builder: (_, s) => FriendCalendarPage(
                  friendId: s.pathParameters['friendId']!,
                ),
              ),
              GoRoute(
                path: ':friendId/merge',
                builder: (_, s) => MergeCalendarPage(
                  friendId: s.pathParameters['friendId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => const ProfilePage(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, _) => const EditProfilePage(),
              ),
              GoRoute(
                path: 'settings',
                builder: (_, _) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),

      // ── 단독 경로 ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.placePicker,
        builder: (_, _) => const PlacePickerPage(),
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});

