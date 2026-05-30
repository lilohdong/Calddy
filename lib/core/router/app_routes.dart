/// 앱 전체 라우트 경로 상수
///
/// 경로 문자열은 이 클래스에서만 정의한다. 페이지에서 하드코딩 금지.
abstract class AppRoutes {
  // ── Auth ────────────────────────────────────────────────────
  static const String splash           = '/splash';
  static const String login            = '/login';
  static const String loginEmail       = '/login/email';
  static const String loginEmailVerify = '/login/email/verify';
  static const String loginEmailForgot = '/login/email/forgot';
  static const String onboarding       = '/onboarding';
  static const String networkError     = '/error';

  // ── Shell (하단 탭 네비게이션) ─────────────────────────────
  static const String home             = '/home';     // 탭: 캘린더
  static const String feed             = '/feed';     // 탭: 피드
  static const String friends          = '/friends';  // 탭: 친구
  static const String profile          = '/profile';  // 탭: 마이페이지

  // ── Calendar ────────────────────────────────────────────────
  static const String eventDetail      = '/home/event/:eventId';
  static const String eventCreate      = '/home/event/create';
  static const String drawing          = '/home/drawing/:date';
  static const String rangeCreate      = '/home/range/create';
  static const String record           = '/home/event/:eventId/record';
  static const String aiMidpoint       = '/map/ai-midpoint';

  /// 런타임 경로 헬퍼 — :eventId 치환 (하드코딩 금지)
  static String eventDetailPath(String eventId) => '/home/event/$eventId';
  static String recordPath(String eventId) => '/home/event/$eventId/record';
  static String drawingPath(String date) => '/home/drawing/$date';

  // ── Feed ────────────────────────────────────────────────────
  static const String postDetail       = '/feed/post/:postId';
  static const String postCreate       = '/feed/post/create';
  static const String postEdit         = '/feed/post/:postId/edit';

  /// 런타임 경로 헬퍼 — :param 치환 (하드코딩 금지)
  static String postDetailPath(String postId) => '/feed/post/$postId';
  static String postEditPath(String postId)   => '/feed/post/$postId/edit';

  // ── Friend ──────────────────────────────────────────────────
  static const String friendSearch     = '/friends/search';
  static const String friendCalendar   = '/friends/:friendId/calendar';
  static const String mergeCalendar    = '/friends/merge';

  // ── Appointment ─────────────────────────────────────────────
  static const String appointmentCreate  = '/home/appointment/create';
  static const String appointmentDetail  = '/home/appointment/:appointmentId';

  // ── Map ─────────────────────────────────────────────────────
  static const String placePicker      = '/map/place-picker';

  // ── Notification ────────────────────────────────────────────
  static const String notifications    = '/notifications';

  // ── User ────────────────────────────────────────────────────
  static const String settings         = '/profile/settings';
  static const String editProfile      = '/profile/edit';
}
