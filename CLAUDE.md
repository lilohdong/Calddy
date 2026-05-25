# Calddy – 프로젝트 컨텍스트 (Claude Code용)

> 이 파일은 Claude Code가 세션 시작 시 자동으로 읽는 프로젝트 컨텍스트입니다.
> 새로운 결정이 생길 때마다 이 파일을 업데이트하세요.

---

## 프로젝트 개요

- **앱 이름**: Calddy
- **목적**: 캘린더 기반 일정 관리 + 친구 공유 + 피드 소셜 앱
- **플랫폼**: Flutter (iOS / Android)
- **백엔드**: Supabase (Auth / PostgreSQL / Storage / Realtime / Edge Functions)
- **상태관리**: Riverpod
- **라우팅**: go_router
- **패키지 구조**: Feature-first Clean Architecture

---
## 프로젝트 개발 기능
구글 스프레드 시트의 calddy_backend_plan_v2 참고
## 팀 구성

| 역할 | 인원 | 숙련도 |
|------|------|--------|
| Flutter 개발자 | 2명 | Dart·Flutter·Supabase 모두 처음, 학습 의지 높음 |
| 백엔드 개발자 | 2명 | Dart·Flutter·Supabase 모두 처음, 학습 의지 높음 |

> **중요**: 전원 입문자이므로 보일러플레이트 템플릿과 레이어 규칙 문서를 반드시 참고할 것.
> 첫 2주는 Auth 도메인을 전원이 함께 짜면서 구조를 체득하는 온보딩 기간으로 운영.

---

## 아키텍처 원칙

### 클린 아키텍처 레이어

```
Presentation  →  Domain  →  Data
(UI/Riverpod)    (순수 Dart)  (Supabase)
```

- **의존성 방향은 항상 안쪽(Domain)으로만** — Domain은 절대 외부(Supabase, Flutter)를 import하지 않음
- **엄격한 UseCase 분리**: 기능 하나 = UseCase 클래스 하나
- **단순 CRUD도 UseCase를 거침** — Presentation에서 Repository 직접 호출 금지
- **Supabase 클라이언트는 DataSource 레이어에서만** 사용

### 레이어별 책임

| 레이어 | 역할 | 금지 사항 |
|--------|------|-----------|
| **Presentation** | UI, Riverpod Notifier/Provider | Supabase 직접 호출, 비즈니스 로직 |
| **Domain** | Entity, UseCase, Repository interface | flutter/supabase import |
| **Data** | Repository 구현체, DataSource, DTO | UI 관련 코드 |

---

## 패키지 구조

```
lib/
├── core/                          # 전역 공통 모듈
│   ├── error/
│   │   ├── exceptions.dart        # DataSource 레이어 예외
│   │   └── failures.dart          # Domain 레이어 실패 타입
│   ├── usecase/
│   │   └── usecase.dart           # UseCase 추상 클래스 (interface)
│   ├── constants/
│   │   ├── supabase_constants.dart # 테이블명, 버킷명 상수
│   │   └── app_constants.dart
│   ├── router/
│   │   ├── app_router.dart        # GoRouter 인스턴스 & routerProvider
│   │   └── app_routes.dart        # 경로 상수 (AppRoutes.login 등)
│   └── utils/
│       └── extensions.dart
│
├── features/
│   ├── auth/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── login_page.dart
│   │   │   │   └── signup_page.dart
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   │       ├── auth_provider.dart      # Riverpod Provider 정의
│   │   │       └── login_notifier.dart     # StateNotifier
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart    # abstract interface
│   │   │   └── usecases/
│   │   │       ├── sign_in_with_email_usecase.dart
│   │   │       ├── sign_up_with_email_usecase.dart
│   │   │       ├── sign_in_with_google_usecase.dart
│   │   │       ├── sign_out_usecase.dart
│   │   │       ├── send_otp_usecase.dart
│   │   │       ├── verify_otp_usecase.dart
│   │   │       ├── reset_password_usecase.dart
│   │   │       └── delete_account_usecase.dart
│   │   └── data/
│   │       ├── datasources/
│   │       │   ├── auth_remote_datasource.dart       # abstract
│   │       │   └── auth_remote_datasource_impl.dart  # Supabase 구현
│   │       ├── models/
│   │       │   └── user_model.dart         # UserEntity + fromJson/toJson
│   │       └── repositories/
│   │           └── auth_repository_impl.dart
│   │
│   ├── calendar/
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── event_entity.dart
│   │   │   │   ├── habit_entity.dart
│   │   │   │   ├── habit_log_entity.dart
│   │   │   │   ├── range_entity.dart
│   │   │   │   └── drawing_entity.dart
│   │   │   ├── repositories/
│   │   │   │   ├── event_repository.dart
│   │   │   │   ├── habit_repository.dart
│   │   │   │   └── drawing_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_calendar_by_month_usecase.dart
│   │   │       ├── get_calendar_by_week_usecase.dart
│   │   │       ├── create_event_usecase.dart
│   │   │       ├── update_event_usecase.dart
│   │   │       ├── delete_event_usecase.dart
│   │   │       ├── complete_event_usecase.dart
│   │   │       ├── create_habit_usecase.dart
│   │   │       ├── toggle_habit_log_usecase.dart
│   │   │       ├── create_range_usecase.dart
│   │   │       ├── save_drawing_usecase.dart
│   │   │       └── get_drawing_usecase.dart
│   │   └── data/
│   │       ├── datasources/
│   │       ├── models/
│   │       └── repositories/
│   │
│   ├── feed/
│   │   ├── presentation/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── post_entity.dart
│   │   │   │   └── comment_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── feed_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_feed_by_date_usecase.dart
│   │   │       ├── create_post_usecase.dart
│   │   │       ├── update_post_usecase.dart
│   │   │       ├── delete_post_usecase.dart
│   │   │       ├── toggle_post_like_usecase.dart
│   │   │       ├── create_comment_usecase.dart
│   │   │       ├── get_comments_usecase.dart
│   │   │       ├── update_comment_usecase.dart
│   │   │       └── delete_comment_usecase.dart
│   │   └── data/
│   │
│   ├── appointment/
│   │   ├── presentation/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── appointment_entity.dart
│   │   │   │   └── invite_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── appointment_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_appointment_usecase.dart
│   │   │       ├── accept_invite_usecase.dart
│   │   │       ├── reject_invite_usecase.dart
│   │   │       └── get_place_suggestion_usecase.dart
│   │   └── data/
│   │
│   ├── friend/
│   │   ├── presentation/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── friend_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── friend_repository.dart
│   │   │   └── usecases/
│   │   │       ├── search_users_usecase.dart
│   │   │       ├── send_friend_request_usecase.dart
│   │   │       ├── accept_friend_request_usecase.dart
│   │   │       ├── reject_friend_request_usecase.dart
│   │   │       ├── get_friends_usecase.dart
│   │   │       ├── delete_friend_usecase.dart
│   │   │       ├── get_friend_calendar_usecase.dart
│   │   │       ├── merge_calendars_usecase.dart
│   │   │       └── suggest_appointment_usecase.dart
│   │   └── data/
│   │
│   ├── map/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── place_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── map_repository.dart
│   │   │   └── usecases/
│   │   │       ├── calculate_midpoint_usecase.dart
│   │   │       └── search_places_usecase.dart
│   │   └── data/
│   │
│   ├── user/
│   │   ├── presentation/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── profile_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── user_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_profile_usecase.dart
│   │   │       ├── update_profile_usecase.dart
│   │   │       ├── update_nickname_usecase.dart
│   │   │       ├── update_birth_date_usecase.dart
│   │   │       ├── get_my_posts_usecase.dart
│   │   │       ├── set_push_notification_usecase.dart
│   │   │       └── withdraw_usecase.dart
│   │   └── data/
│   │
│   ├── notification/
│   │   ├── presentation/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── notification_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── notification_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_notifications_usecase.dart
│   │   │       ├── delete_notification_usecase.dart
│   │   │       ├── delete_all_notifications_usecase.dart
│   │   │       └── mark_notification_read_usecase.dart
│   │   └── data/
│   │
│   └── report/
│       ├── domain/
│       │   ├── entities/
│       │   │   └── report_entity.dart
│       │   ├── repositories/
│       │   │   └── report_repository.dart
│       │   └── usecases/
│       │       └── report_post_usecase.dart
│       └── data/
│
└── main.dart
```

---

## 도메인 엔티티 명세

### UserEntity (auth / user 공용)
```dart
class UserEntity {
  final String id;            // auth.uid()
  final String email;
  final String nickname;
  final String? avatarUrl;    // Supabase Storage URL
  final DateTime? birthDate;
  final bool pushEnabled;
  final String? fcmToken;
  final DateTime createdAt;
}
```

### EventEntity
```dart
class EventEntity {
  final String id;
  final String userId;
  final String title;
  final String? location;
  final double? locationLat;
  final double? locationLng;
  final DateTime startAt;
  final DateTime endAt;
  final String color;         // hex (#FF5733)
  final bool isDday;
  final String? memo;
  final int? notifyBeforeMin; // 알림 시간(분)
  final EventStatus status;   // pending | done
  final String? appointmentId;
  final EventVisibility visibility; // public | private
  final DateTime createdAt;
}

enum EventStatus { pending, done }
enum EventVisibility { public, private }
```

### HabitEntity
```dart
class HabitEntity {
  final String id;
  final String userId;
  final String title;
  final String color;
  final RecurrenceType recurrenceType; // daily | weekly | monthly
  final List<int>? recurrenceDays;     // 요일(0~6) 또는 일(1~31)
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
}

enum RecurrenceType { daily, weekly, monthly }
```

### HabitLogEntity
```dart
class HabitLogEntity {
  final String id;
  final String habitId;
  final DateTime logDate;
  final bool isDone;
}
```

### RangeEntity
```dart
class RangeEntity {
  final String id;
  final String userId;
  final String title;
  final String color;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
}
```

### DrawingEntity
```dart
class DrawingEntity {
  final String id;
  final String userId;
  final DateTime drawDate;
  final List<DrawingStroke> strokes;  // jsonb로 저장
  final String? thumbnailUrl;         // 추후 썸네일 확장용
  final DateTime updatedAt;
}

class DrawingStroke {
  final String color;
  final double width;
  final List<List<double>> points;  // [[x,y], [x,y], ...]
}
```

### PostEntity
```dart
class PostEntity {
  final String id;
  final String userId;
  final String? eventId;        // 연동된 일정 (nullable)
  final String? content;
  final String? imageUrl;       // Supabase Storage URL
  final PostVisibility visibility;
  final int likesCount;
  final bool isLikedByMe;       // 조회 시 join
  final DateTime feedDate;      // 피드 날짜 기준
  final DateTime createdAt;
}

enum PostVisibility { public, private }
```

### CommentEntity
```dart
class CommentEntity {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
}
```

### AppointmentEntity
```dart
class AppointmentEntity {
  final String id;
  final String eventId;
  final String creatorId;
  final String? suggestedPlace;
  final List<InviteEntity> invites;
  final DateTime createdAt;
}

class InviteEntity {
  final String id;
  final String appointmentId;
  final String inviteeId;
  final InviteStatus status;   // pending | accepted | rejected
  final DateTime updatedAt;
}

enum InviteStatus { pending, accepted, rejected }
```

### FriendEntity
```dart
class FriendEntity {
  final String userId;
  final String friendId;
  final UserEntity friendProfile;
  final FriendRequestStatus status;
  final DateTime createdAt;
}

enum FriendRequestStatus { pending, accepted, rejected }
```

### PlaceEntity
```dart
class PlaceEntity {
  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double? distanceFromMidpoint;
}
```

### NotificationEntity
```dart
class NotificationEntity {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final String? relatedId;  // 관련 리소스 ID
  final DateTime createdAt;
}

enum NotificationType {
  friendRequest,
  appointmentInvite,
  appointmentAccepted,
  appointmentRejected,
  suggestNewDate,
  postLiked,
  postCommented,
}
```

### ProfileEntity
```dart
class ProfileEntity {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final DateTime? birthDate;
  final bool pushEnabled;
}
```

### ReportEntity
```dart
class ReportEntity {
  final String id;
  final String reporterId;
  final ReportTargetType targetType;  // post | comment | user
  final String targetId;
  final String reason;
  final ReportStatus status;           // pending | reviewed
  final DateTime createdAt;
}

enum ReportTargetType { post, comment, user }
enum ReportStatus { pending, reviewed }
```

---

## UseCase 추상 클래스 (core/usecase/usecase.dart)

```dart
// 모든 UseCase는 이 인터페이스를 구현
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

// 파라미터 없는 UseCase용
class NoParams {}
```

---

## Supabase 테이블 & 버킷 상수 (core/constants/supabase_constants.dart)

```dart
class SupabaseConstants {
  // Tables
  static const String profiles         = 'profiles';
  static const String events           = 'events';
  static const String habits           = 'habits';
  static const String habitLogs        = 'habit_logs';
  static const String ranges           = 'ranges';
  static const String drawings         = 'drawings';
  static const String posts            = 'posts';
  static const String postLikes        = 'post_likes';
  static const String comments         = 'comments';
  static const String appointments     = 'appointments';
  static const String appointmentInvites = 'appointment_invites';
  static const String friendRequests   = 'friend_requests';
  static const String friends          = 'friends';
  static const String notifications    = 'notifications';
  static const String reports          = 'reports';
  static const String holidays         = 'holidays';

  // Storage Buckets
  static const String avatarsBucket    = 'avatars';
  static const String postsBucket      = 'posts';
  static const String drawingsBucket   = 'drawings';
}
```

---

## Riverpod Provider 패턴 (Feature별 동일 구조 적용)

```dart
// 1. DataSource Provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(Supabase.instance.client);
});

// 2. Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

// 3. UseCase Provider
final signInUseCaseProvider = Provider((ref) {
  return SignInWithEmailUseCase(ref.watch(authRepositoryProvider));
});

// 4. Notifier (StateNotifier)
final loginNotifierProvider =
StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref.watch(signInUseCaseProvider));
});
```

---

## 라우팅 (go_router)

### 구조 원칙

- **GoRouter 인스턴스는 `core/router/app_router.dart` 한 곳에서만 관리**
- **경로 문자열은 `AppRoutes` 상수 클래스에서만 정의** — 하드코딩 금지
- **인증 상태에 따른 redirect 로직은 GoRouter의 `redirect` 콜백에서 처리** — 각 페이지에서 개별 처리 금지
- **중첩 라우팅(ShellRoute)으로 하단 탭 네비게이션 구현**

### 경로 상수 (core/router/app_routes.dart)

```dart
class AppRoutes {
  // Auth
  static const String splash        = '/';
  static const String login         = '/login';
  static const String signup        = '/signup';
  static const String emailVerify   = '/signup/verify';
  static const String forgotPassword = '/forgot-password';

  // Shell (탭 네비게이션)
  static const String home          = '/home';          // 탭: 캘린더
  static const String feed          = '/feed';          // 탭: 피드
  static const String friends       = '/friends';       // 탭: 친구
  static const String profile       = '/profile';       // 탭: 마이페이지

  // Calendar
  static const String eventDetail   = '/home/event/:eventId';
  static const String eventCreate   = '/home/event/create';
  static const String drawing       = '/home/drawing/:date';

  // Feed
  static const String postDetail    = '/feed/post/:postId';
  static const String postCreate    = '/feed/post/create';

  // Friend
  static const String friendCalendar = '/friends/:friendId/calendar';
  static const String mergeCalendar  = '/friends/:friendId/merge';

  // Appointment
  static const String appointmentCreate = '/home/appointment/create';
  static const String appointmentDetail = '/home/appointment/:appointmentId';

  // Map
  static const String placePicker   = '/map/place-picker';

  // Notification
  static const String notifications = '/notifications';

  // User
  static const String settings      = '/profile/settings';
  static const String editProfile   = '/profile/edit';
}
```

### GoRouter 설정 (core/router/app_router.dart)

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider); // Supabase 세션 감지

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup') ||
          state.matchedLocation == AppRoutes.splash;

      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn && isAuthRoute)  return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash,         builder: (_, __) => const SplashPage()),
      GoRoute(path: AppRoutes.login,          builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.signup,         builder: (_, __) => const SignupPage()),
      GoRoute(path: AppRoutes.emailVerify,    builder: (_, __) => const EmailVerifyPage()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordPage()),

      // 하단 탭 Shell
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const CalendarPage(),
            routes: [
              GoRoute(path: 'event/create',          builder: (_, __) => const EventCreatePage()),
              GoRoute(path: 'event/:eventId',        builder: (_, s) => EventDetailPage(eventId: s.pathParameters['eventId']!)),
              GoRoute(path: 'drawing/:date',         builder: (_, s) => DrawingPage(date: s.pathParameters['date']!)),
              GoRoute(path: 'appointment/create',    builder: (_, __) => const AppointmentCreatePage()),
              GoRoute(path: 'appointment/:appointmentId', builder: (_, s) => AppointmentDetailPage(id: s.pathParameters['appointmentId']!)),
            ],
          ),
          GoRoute(
            path: AppRoutes.feed,
            builder: (_, __) => const FeedPage(),
            routes: [
              GoRoute(path: 'post/create',    builder: (_, __) => const PostCreatePage()),
              GoRoute(path: 'post/:postId',   builder: (_, s) => PostDetailPage(postId: s.pathParameters['postId']!)),
            ],
          ),
          GoRoute(
            path: AppRoutes.friends,
            builder: (_, __) => const FriendPage(),
            routes: [
              GoRoute(path: ':friendId/calendar', builder: (_, s) => FriendCalendarPage(friendId: s.pathParameters['friendId']!)),
              GoRoute(path: ':friendId/merge',    builder: (_, s) => MergeCalendarPage(friendId: s.pathParameters['friendId']!)),
            ],
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfilePage(),
            routes: [
              GoRoute(path: 'edit',     builder: (_, __) => const EditProfilePage()),
              GoRoute(path: 'settings', builder: (_, __) => const SettingsPage()),
            ],
          ),
        ],
      ),

      GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsPage()),
      GoRoute(path: AppRoutes.placePicker,   builder: (_, __) => const PlacePickerPage()),
    ],
  );
});
```

### 네비게이션 사용 규칙

```dart
// ✅ 올바른 사용 — AppRoutes 상수 + context.go / context.push
context.go(AppRoutes.home);
context.push(AppRoutes.eventCreate);
context.push('/home/event/${event.id}');

// ✅ 뒤로가기
context.pop();

// ❌ 금지 — 경로 문자열 하드코딩
context.go('/home/event/create');   // AppRoutes 상수 사용할 것
Navigator.of(context).push(...);    // go_router로 통일
```

### 인증 리다이렉트 흐름

```
앱 시작
  │
  ▼
SplashPage ── 세션 확인 ──► 세션 없음 ──► LoginPage
                │
                ▼
            세션 있음 ──► CalendarPage (ShellRoute)
```

### PR 체크리스트 추가 항목 (라우팅)

- [ ] 새 페이지 경로는 `AppRoutes`에 상수로 추가됨
- [ ] `Navigator.of(context).push` 사용 없음 (go_router로 통일)
- [ ] 인증 필요 페이지는 GoRouter `redirect`에서 처리, 페이지 내부 처리 없음
- [ ] 경로 파라미터는 `state.pathParameters`로 수신



### 레벨 0 – 시스템 전체

```
[Flutter App] ──── Auth / CRUD ────► [Supabase PostgreSQL + RLS]
[Flutter App] ──── 파일 업로드 ────► [Supabase Storage]
[Flutter App] ◄─── Realtime ────── [Supabase Realtime]
[Flutter App] ◄─── FCM 푸시 ─────  [Edge Function → Firebase FCM]
[Edge Fn]     ──── 외부 API ─────► [Google Maps API / SMTP]
```

### 핵심 데이터 흐름

| 흐름 | 경로 |
|------|------|
| 로그인 | App → supabase.auth → JWT → profiles 자동 생성(트리거) |
| 일정 생성 | App → events INSERT → (알림 예약) Edge Fn → FCM |
| 피드 이미지 | App → Storage upload → URL → posts INSERT |
| 친구 초대 | App → appointments INSERT → Edge Fn → FCM → invitee |
| 수락 동기화 | invitee 수락 → DB 트리거 → events 복제 INSERT |
| 드로잉 저장 | App → drawings UPSERT (jsonb strokes) → 썸네일 선택적 Storage 저장 |
| 실시간 알림 | DB INSERT on notifications → Realtime → App 즉시 수신 |

---

## 협업 규칙

### Failure 클래스 추가 방법

`lib/core/error/failures.dart`는 **배럴 export 파일**입니다. 직접 수정하지 마세요.

```
lib/core/error/
├── failures.dart              ← export만 있음 — 여기 직접 클래스 작성 금지
└── failures/
    ├── auth_failure.dart      ← Auth 팀이 소유
    ├── calendar_failure.dart  ← Calendar 팀이 소유
    ├── appointment_failure.dart
    ├── drawing_failure.dart
    ├── friend_failure.dart    ← Friend 팀이 소유
    └── map_failure.dart       ← Map 팀이 소유
```

**새 도메인 Failure 추가 절차:**

1. `lib/core/error/failures/<feature>_failure.dart` 파일 신규 생성
2. `lib/core/error/failures.dart`에 export 한 줄만 추가:
   ```dart
   export 'failures/<feature>_failure.dart';
   ```
3. 기존 `import 'package:calddy/core/error/failures.dart'` 구문 변경 불필요

> **이유**: 단일 파일에 전원이 추가하면 git merge conflict가 반드시 발생합니다.
> 파일을 분리하면 각자 자기 파일만 수정하므로 충돌이 사라집니다.

---

### DataSource 반환 타입 규칙

- **DataSource 인터페이스** → 반환 타입은 **Model** (예: `MidpointResultModel`)
- **Repository 인터페이스** → 반환 타입은 **Entity** (예: `MidpointResultEntity`)
- Repository Impl이 DataSource 결과(Model)를 Entity로 업캐스트

> Model은 Entity를 상속하므로 Repository Impl에서 별도 변환 없이 반환 가능합니다.

---

### FutureProvider 내 ref 사용 규칙

```dart
// ✅ FutureProvider 안에서는 ref.read
final myProvider = FutureProvider.autoDispose.family<..., ...>((ref, param) {
  return ref.read(someUseCaseProvider).call(params);
});

// ❌ FutureProvider 안에서 ref.watch 사용 금지
//    (구독 관계를 올바르게 추적하지 못해 중복 실행 발생 가능)
```

---

## PR 체크리스트 (레이어 위반 방지)

PR 올리기 전 아래 항목 자체 점검 필수:

- [ ] `presentation/` 에서 `Supabase.instance.client` 직접 사용 없음
- [ ] `domain/` 에서 `supabase`, `flutter` package import 없음
- [ ] 새 기능에 UseCase 클래스 존재함
- [ ] Repository는 abstract interface(domain)와 구현체(data) 분리됨
- [ ] 새 Entity는 `entities/` 에만 정의, Model은 `models/` 에만 정의
- [ ] **DataSource 인터페이스 반환 타입이 Model, Repository 반환 타입이 Entity**
- [ ] Riverpod Provider 체인이 DataSource → Repository → UseCase → Notifier 순서임
- [ ] **FutureProvider 내부에서 `ref.read` 사용 (ref.watch 금지)**
- [ ] 테이블명·버킷명은 `SupabaseConstants` 상수 사용
- [ ] 새 페이지 경로는 `AppRoutes`에 상수로 추가됨
- [ ] `Navigator.of(context).push` 사용 없음 (go_router로 통일)
- [ ] 인증 필요 페이지의 접근 제어는 GoRouter `redirect`에서만 처리
- [ ] **새 Failure 클래스는 `failures/<feature>_failure.dart`에 작성, `failures.dart`에 export 추가**

---

## 기술 스택 & 주요 패키지

| 용도 | 패키지 |
|------|--------|
| 라우팅 | `go_router` |
| Supabase 연동 | `supabase_flutter` |
| 상태관리 | `flutter_riverpod` |
| Google 로그인 | `google_sign_in` |
| FCM 푸시 | `firebase_messaging` |
| 로컬 알림 | `flutter_local_notifications` |
| 이미지 선택 | `image_picker` |
| 지도 렌더링 | `flutter_naver_map` |
| 드로잉 | `perfect_freehand` 또는 `flutter_drawing_board` |
| 로컬 캐싱 | `shared_preferences` |
| DI 확인 | `riverpod_lint` (린트 룰로 레이어 위반 감지) |

---

## 개발 우선순위 (스프린트 가이드)

| 스프린트 | 목표 | 비고 |
|---------|------|------|
| Sprint 1 (1~2주) | **Auth 도메인 전체** 전원 함께 구현 | 구조 체득 온보딩 |
| Sprint 2 (3~4주) | Calendar (일정 CRUD) + User 프로필 | 핵심 기능 |
| Sprint 3 (5~6주) | Feed + Notification | 소셜 기능 |
| Sprint 4 (7~8주) | Friend + Appointment | 복합 도메인 |
| Sprint 5 (9~10주) | Map + Drawing + Report | 마무리 |

---

*최종 업데이트: go_router 라우팅 구조 추가 (Feature-first / Riverpod / go_router / 엄격한 클린 아키텍처 + 온보딩 전략)*

---

## DFD (Data Flow Diagram)

### Level 0 – 시스템 전체

```
                        ┌─────────────────────┐
                        │     Flutter App      │
                        │  go_router·Riverpod  │
                        └──────────┬───────────┘
           ┌────────────┬──────────┼──────────┬────────────┐
           │            │          │          │            │
    로그인 요청     CRUD 요청   파일 업로드   구독       DB 트리거
           │            │          │          │            │
           ▼            ▼          ▼          ▼            ▼
   ┌──────────────┐ ┌──────────┐ ┌─────────┐ ┌─────────┐ ┌──────────────┐
   │Supabase Auth │ │Supabase  │ │Supabase │ │Supabase │ │Edge Functions│
   │JWT·OAuth·OTP │ │   DB     │ │ Storage │ │Realtime │ │Deno·서버로직  │
   └──────┬───────┘ │PostgreSQL│ │avatars  │ │알림·좋아요│ └──────┬───────┘
          │         │+RLS      │ │posts    │ │댓글      │        │
       JWT 발급      └──────────┘ │drawings │ └─────────┘     FCM 발송
          │                      └─────────┘                     │
          └──────────────────────────────────────────────────────┤
                                                                  ▼
                                                         ┌───────────────┐
                                                         │ Firebase FCM  │
                                                         │   푸시 알림    │
                                                         └───────────────┘

   Flutter App ──장소 검색──▶ Edge Fn ──▶ Google Maps API
               ◀─결과 반환──            ◀─ Geocoding·장소
```

---

### Level 1 – Auth

```
  [Presentation]         [Domain]            [Data]              [Supabase]

  LoginPage         SignInWithEmail       AuthRemote          Supabase Auth
  이메일/Google  ──▶   UseCase        ──▶  DataSource  ──▶  signInWithPassword
                     비밀번호 검증                              signInWithOAuth
                          │                                         │
                          ▼                                      JWT 발급
                    AuthRepository                                   │
                     (interface)                             ┌───────┴────────┐
                          │                                  │                │
                          ▼                              세션 저장소      DB 트리거
                    AuthRepository                       자동 갱신    on_auth_user
                      (impl)                              (SDK)         _created
                                                                            │
                                                                            ▼
  routerProvider ◀── 세션 감지 ──────────────────────── profiles 테이블
  redirect→/home                                          자동 INSERT
```

---

### Level 1 – Feed

```
  [Presentation]         [Domain]            [Supabase]

  FeedPage          GetFeedByDate        posts 테이블
  날짜 선택     ──▶    UseCase      ──▶  RLS·cursor 페이지네이션
                                               │
                                        응답 (날짜별 피드)
                                               │
                                               ▼
  PostCreatePage    CreatePost           Supabase Storage
  텍스트·이미지  ──▶   UseCase      ──▶  posts 버킷 업로드
                                               │
                                           URL 저장
                                               │
                                               ▼
                                         posts INSERT
                                        image_url·event_id
                                               │
  좋아요 버튼      TogglePostLike        post_likes 테이블
  UI 토글      ──▶   UseCase      ──▶   UNIQUE upsert
                                               │
                                          DB 트리거
                                        likes_count 집계
                                               │
                          ┌────────────────────┤
                          │                    │
                          ▼                    ▼
                     Realtime            notifications
                   좋아요 수 반영         postLiked 생성
                          │
                          ▼
                     FeedPage UI
                     실시간 업데이트

  댓글 영역    ──▶ comments 테이블 ──▶ notifications (댓글 알림)
  Create·Get       post_id FK·RLS
  Delete
```

---

### Level 1 – Calendar

```
  [Presentation]         [Domain]            [Supabase]

  CalendarPage      GetCalendarByMonth    Supabase RPC
  월별/주별      ──▶  /ByWeek UseCase  ──▶ events+habits
                                            +ranges 병합
                                            +holidays 조회

  EventCreatePage   CreateEvent          events 테이블
  장소·시간·색상 ──▶   UseCase      ──▶  RLS·status enum
  메모·알림                                     │
                                          Edge Fn → FCM
                                            알림 예약
                                               │
                    CompleteEvent     status: pending→done
                      UseCase     ──▶       │
                                            ▼
                                       '기록하기' 권한
                                       Feed 생성 연동

  습관 설정        CreateHabit          habits 테이블
  매일·매주·매월 ──▶   UseCase      ──▶  recurrence rule
                                               │
                                          habit_logs
                   ToggleHabitLog     ──▶  날짜별 upsert
                     UseCase

  DrawingPage        SaveDrawing         drawings 테이블
  손그림 편집    ──▶    UseCase      ──▶  jsonb strokes
                                            upsert
                                        (user_id, date UNIQUE)
```

---

### Level 1 – Appointment

```
  생성자               [Domain]            [Supabase]

  일정+친구태그    CreateAppointment    appointments 테이블
  선택         ──▶    UseCase      ──▶  + invites INSERT
                                               │
                                          DB 트리거
                                               │
                                          Edge Fn
                                        FCM 푸시 발송
                                               │
                                               ▼
  수신자 (invitee) ◀──────────── 푸시 수신
       │
       ├── 수락 ──▶ AcceptInvite ──▶ invites.status = accepted
       │              UseCase              │
       │                             DB 트리거
       │                        events 복제 INSERT
       │                               │
       │                               ▼
       │                        invitee 캘린더
       │                         일정 자동 동기화
       │
       │                         ┌─────────────────────┐
       │                         │  Map Edge Function  │
       └── 수락 시 ──────────────▶│  출발지 기반 계산    │
                                 │  Google Maps API 호출│
                                 └──────────┬──────────┘
                                            │
                                            ▼
                                   appointments 테이블
                                   suggested_place 저장

       └── 거절 ──▶ RejectInvite ──▶ notifications 테이블
                      UseCase         type: suggest_new_date
                                               │
                                          Realtime
                                      생성자에게 즉시 전달
```

---

### Level 1 – Friend

```
  [Presentation]         [Domain]            [Supabase]

  FriendPage         SearchUsers          profiles 테이블
  닉네임/ID 검색  ──▶   UseCase      ──▶  ilike·pg_trgm 인덱스

  친구 추가 버튼    SendFriendRequest    friend_requests 테이블
               ──▶    UseCase      ──▶   UNIQUE 중복 방지
                                               │
                                     ┌─────────┴──────────┐
                                     │                    │
                                Edge Fn → FCM      수신자 수락/거절
                               friendRequest 알림         │
                                                    AcceptFriend
                                                      Request
                                                      UseCase
                                                          │
                                                     friends 테이블
                                                     양방향 INSERT

  친구 캘린더 탭    GetFriendCalendar    events 테이블
  공개 일정 보기 ──▶    UseCase      ──▶  visibility=public
                                          RLS 필터 (친구 검증)

  합쳐보기 버튼    MergeCalendars       RPC free_slots
               ──▶    UseCase      ──▶  빈 시간 교차 계산
                                               │
                                               ▼
  일정 제안 버튼    SuggestAppointment   Appointment 도메인
  빈 날짜 선택  ──▶    UseCase      ──▶  appointments INSERT
```

---

### Level 1 – Notification · User · Report

```
  ── Notification ──────────────────────────────────────────────

  NotificationsPage   GetNotifications    notifications 테이블
  목록·읽음·삭제   ──▶  /MarkRead      ──▶  is_read·type
                        UseCase                  │
                                            Realtime 구독
                                           신규 알림 실시간 수신
                                                 │
                                         Edge Fn → FCM
                                          타입별 푸시 발송
                                                 │
                                                 ▼
                                          Flutter App 수신

  ── User ──────────────────────────────────────────────────────

  ProfilePage         UpdateProfile        profiles 테이블
  조회·수정        ──▶    UseCase      ──▶  nickname·birth_date
                                                 │
                                         Storage avatars 버킷
                                          이미지 업로드 → URL

  SettingsPage        SetPushNotification  profiles.fcm_token
  푸시 ON/OFF      ──▶    UseCase      ──▶  firebase_messaging

  탈퇴 버튼           WithdrawUseCase      Edge Fn
                   ──▶                ──▶  auth.admin.deleteUser
                                           + 개인정보 익명화

  ── Report ────────────────────────────────────────────────────

  신고 버튼            ReportPost           reports 테이블
  게시글·댓글·유저 ──▶    UseCase      ──▶  target_type (polymorphic)
                                           UNIQUE 중복 방지
                                                 │
                                         status: pending→reviewed
                                              (관리자 처리)

  확장 예정: target_type = 'comment' | 'user'  (P3)
```


---

## 캘린더 개발 전략 (2026-04-30 결정)

### 결정 사항

| 항목 | 결정 |
|------|------|
| **Google Calendar API 연동** | 미사용 — 습관·드로잉·피드 연동 등 Calddy 고유 기능이 Google Calendar 미지원 |
| **캘린더 데이터 저장** | 자체 Supabase DB (events / habits / habit_logs / ranges / drawings) |
| **향후 Google Calendar 연동** | 자체 캘린더 완성 후 "외부 일정 가져오기" P3 부가 기능으로 추가 예정 |

> Google Calendar API를 쓰면 구글 로그인이 사실상 필수가 되고,
> 습관 체크박스·손그림·피드 연동 기능을 별도로 Supabase에 구현해야 해서 이중 구조가 됨.

---

### 핵심 패키지 (캘린더 UI 공수 절감)

| 패키지 | 용도 | 절감 효과 |
|--------|------|-----------|
| table_calendar ^3.1.x | 월별/주별 캘린더 UI, 이벤트 마커, 날짜 선택 | 캘린더 UI 3~4주 -> 3~5일 |
| perfect_freehand ^2.0.x | 손그림 stroke 렌더링 | 드로잉 UI 2~3주 -> 1주 |

> table_calendar: 커스텀 셀 빌더로 습관 체크박스, 구간 색상 표시, 공휴일 마커 모두 구현 가능.

---

### 현실적 공수 (입문자 팀 4명 기준)

| 접근 방식 | 예상 기간 |
|-----------|-----------|
| 순수 자체 개발 (패키지 미사용) | 12~16주 |
| **패키지 활용 (권장)** | **7~10주** |

---

### 최우선 리스크: 습관 반복 로직

습관 인스턴스 생성 전략을 개발 전 반드시 결정해야 함 — 잘못 설계하면 전면 재작업 필요.

| 전략 | 설명 | 권장 여부 |
|------|------|-----------|
| **Lazy 생성** | 캘린더 조회 시점에 habit_logs 없으면 그때 생성 | 권장 (Supabase RPC) |
| Eager 생성 | 습관 저장 시 전체 인스턴스 미리 INSERT | 비권장 (rows 폭증 위험) |

---

### Auth 미구현 P1 항목 (Sprint 1 후속 작업)

| 기능 | 필요 작업 | 예상 공수 |
|------|-----------|-----------|
| 이용 약관 동의 저장 | DB 마이그레이션 + UserEntity 필드 추가 + 온보딩 UI | 2h |
| 이메일 OTP 발송/검증 | AuthRepository 메서드 추가 -> DataSource 구현 -> OTP 입력 UI | 5h |
| 비밀번호 서버사이드 검증 | Supabase 대시보드 Auth Hook 설정 (Flutter 코드 변경 불필요) | 3h |
