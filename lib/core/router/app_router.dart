import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/email_auth_page.dart';
import '../../features/auth/presentation/pages/email_verify_page.dart';
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
import '../../features/calendar/presentation/pages/range_create_page.dart';
import '../../features/calendar/presentation/pages/record_page.dart';
import '../../features/map/presentation/pages/ai_midpoint_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/feed/presentation/pages/post_detail_page.dart';
import '../../features/feed/presentation/pages/post_edit_page.dart';
import '../../features/report/presentation/pages/report_post_page.dart';
import '../../features/feed/domain/entities/post_entity.dart';
import '../../features/friend/presentation/pages/friend_calendar_page.dart';
import '../../features/friend/presentation/pages/friend_search_page.dart';
import '../../features/friend/presentation/pages/friends_page.dart';
import '../../features/friend/presentation/pages/merge_calendar_page.dart';
import '../../features/map/presentation/pages/place_picker_page.dart';
import '../../features/notification/presentation/pages/notifications_page.dart';
import '../../features/user/presentation/pages/birth_date_setting_page.dart';
import '../../features/user/presentation/pages/edit_profile_page.dart';
import '../../features/user/presentation/pages/email_setting_page.dart';
import '../../features/user/presentation/pages/logout_page.dart';
import '../../features/user/presentation/pages/notification_settings_page.dart';
import '../../features/user/presentation/pages/profile_page.dart';
import '../../features/user/presentation/pages/settings_page.dart';
import '../../features/user/presentation/pages/withdraw_page.dart';
import 'app_routes.dart';
import 'main_shell.dart';

/// authStateProvider 변경 시 GoRouter에 리프레시 신호를 보내는 노티파이어
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    // 스플래시 최소 노출 시간 (2.5초) — disposed 후 콜백 방어
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (_disposed) return;
      _splashReady = true;
      notifyListeners();
    });
  }

  final Ref _ref;
  bool _splashReady = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final location = state.matchedLocation;

    // 스플래시 최소 노출 시간 미경과 → 스플래시 유지
    if (!_splashReady) {
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    }

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

    // 로그인 + 온보딩 완료 → 인증 경로에 있으면 피드(홈탭)으로
    if (location == AppRoutes.splash ||
        location.startsWith(AppRoutes.login) ||
        location == AppRoutes.onboarding) {
      return AppRoutes.feed;
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
                path: 'verify',
                builder: (_, s) => EmailVerifyPage(
                  email: s.extra is String ? s.extra as String : '',
                ),
              ),
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
                builder: (_, s) => EventCreatePage(
                  extra: s.extra is EventCreateExtra
                      ? s.extra as EventCreateExtra
                      : null,
                ),
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
                path: 'range/create',
                builder: (_, s) => RangeCreatePage(
                  prefilledDate: s.extra is DateTime ? s.extra as DateTime : null,
                ),
              ),
              GoRoute(
                path: 'event/:eventId/record',
                builder: (_, s) => RecordPage(
                  eventId: s.pathParameters['eventId']!,
                  isEditing: s.extra == true,
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
                path: 'post/:postId',
                builder: (_, s) => PostDetailPage(
                  postId: s.pathParameters['postId']!,
                  post: s.extra as PostEntity?,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, s) => PostEditPage(
                      post: s.extra as PostEntity,
                    ),
                  ),
                  GoRoute(
                    path: 'report',
                    builder: (_, s) => ReportPostPage(
                      postId: s.pathParameters['postId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.friends,
            builder: (_, _) => const FriendsPage(),
            routes: [
              GoRoute(
                path: 'search',
                builder: (_, _) => const FriendSearchPage(),
              ),
              GoRoute(
                path: 'merge',
                builder: (_, _) => const MergeCalendarPage(),
              ),
              GoRoute(
                path: ':friendId/calendar',
                builder: (_, s) => FriendCalendarPage(
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
              GoRoute(
                path: 'email',
                builder: (_, _) => const EmailSettingPage(),
              ),
              GoRoute(
                path: 'birth-date',
                builder: (_, _) => const BirthDateSettingPage(),
              ),
              GoRoute(
                path: 'notification',
                builder: (_, _) => const NotificationSettingsPage(),
              ),
              GoRoute(
                path: 'logout',
                builder: (_, _) => const LogoutPage(),
              ),
              GoRoute(
                path: 'withdraw',
                builder: (_, _) => const WithdrawPage(),
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
        builder: (_, s) => PlacePickerPage(
          appointmentId: s.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.aiMidpoint,
        builder: (_, s) {
          final extra = s.extra;
          // 단일 친구(일반 태그) → String
          // 다중 친구(합쳐보기) → List<String>
          // 약속 ID 연동 → Map{'appointmentId': String, 'friendId'?: String}
          return AiMidpointPage(
            friendId: extra is String
                ? extra
                : (extra is Map ? extra['friendId'] as String? : null),
            friendIds: extra is List<String> ? extra : null,
            appointmentId:
                extra is Map ? extra['appointmentId'] as String? : null,
          );
        },
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});

