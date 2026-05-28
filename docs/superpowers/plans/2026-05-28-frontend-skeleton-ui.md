# Calddy 프론트엔드 UI 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 백엔드 Provider 체인에 연결된 스켈레톤 화면을 피그마 디자인 기준으로 도메인별 완성 UI로 구현한다.

**Architecture:** 각 도메인의 기존 Provider (DataSource → Repository → UseCase → Provider) 는 이미 구현되어 있으므로 `presentation/` 레이어만 건드린다. 목업 데이터는 `AsyncValue.data(mockList)` 패턴으로 Provider override 없이 위젯 내부에서 관리하고, 실제 데이터 연결은 이미 된 Provider를 `ref.watch` 로 연결한다.

**Tech Stack:** Flutter, Riverpod (flutter_riverpod ^2.5.1), go_router ^14.0.0, table_calendar ^3.1.x, perfect_freehand, intl ^0.19.0

---

## 파일 현황 (생성/수정 대상)

### 기존 파일 수정
| 파일 | 현재 상태 | 작업 내용 |
|------|-----------|-----------|
| `pubspec.yaml` | table_calendar 등 미설치 | 누락 패키지 5개 추가 |
| `lib/main.dart` | deepPurple seed | 파스텔 퍼플 테마로 교체 |
| `lib/core/router/main_shell.dart` | 기본 NavigationBar | 디자인 적용 |
| `lib/features/auth/presentation/pages/login_page.dart` | 기본 버튼 | Figma 디자인 적용 |
| `lib/features/calendar/presentation/pages/calendar_page.dart` | placeholder | table_calendar + 실제 Provider 연결 |
| `lib/features/feed/presentation/pages/feed_page.dart` | 기본 ListTile | 카드 UI로 교체 |
| `lib/features/feed/presentation/pages/post_create_page.dart` | 미확인 | Figma 적용 |
| `lib/features/feed/presentation/pages/post_detail_page.dart` | 미확인 | Figma 적용 |
| `lib/features/friend/presentation/pages/friends_page.dart` | 기본 UI | Figma 적용 |
| `lib/features/user/presentation/pages/profile_page.dart` | placeholder | Figma 적용 |
| `lib/features/notification/presentation/pages/notifications_page.dart` | placeholder | Figma 적용 |

### 새로 생성
| 파일 | 용도 |
|------|------|
| `lib/core/theme/app_colors.dart` | 전역 색상 상수 |
| `lib/core/theme/app_text_styles.dart` | 전역 텍스트 스타일 |
| `lib/core/theme/app_theme.dart` | ThemeData 생성 |
| `lib/core/widgets/calddy_button.dart` | 공용 버튼 컴포넌트 |
| `lib/core/widgets/calddy_card.dart` | 공용 카드 컴포넌트 |
| `lib/core/widgets/empty_state.dart` | 빈 화면 공용 위젯 |
| `lib/features/calendar/presentation/pages/event_create_page.dart` | 일정 만들기 |
| `lib/features/calendar/presentation/pages/event_detail_page.dart` | 일정 상세 |
| `lib/features/calendar/presentation/pages/drawing_page.dart` | 손그림 |
| `lib/features/calendar/presentation/widgets/calendar_event_marker.dart` | 달력 마커 |
| `lib/features/calendar/presentation/widgets/event_bottom_sheet.dart` | 날짜 탭 시 이벤트 목록 |
| `lib/features/user/presentation/pages/edit_profile_page.dart` | 프로필 편집 |
| `lib/features/user/presentation/pages/settings_page.dart` | 설정 |
| `lib/features/appointment/presentation/pages/appointment_create_page.dart` | 약속 만들기 |
| `lib/features/appointment/presentation/pages/appointment_detail_page.dart` | 약속 상세 |
| `lib/features/map/presentation/pages/place_picker_page.dart` | 장소 선택 (기존 파일 확인 필요) |

---

## Task 1: 누락 패키지 추가 + 테마 컬러 설계

**목표:** table_calendar, perfect_freehand 설치 + 파스텔 퍼플 디자인 시스템 구축

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_text_styles.dart`
- Create: `lib/core/theme/app_theme.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: pubspec.yaml에 누락 패키지 추가**

`dependencies:` 섹션에 아래를 추가:
```yaml
  table_calendar: ^3.1.2
  perfect_freehand: ^2.0.1
  shared_preferences: ^2.3.2
  cached_network_image: ^3.3.1
```

- [ ] **Step 2: 패키지 설치**

```bash
cd D:\calddy
flutter pub get
```

Expected output: `Got dependencies!`

- [ ] **Step 3: AppColors 생성**

파일: `lib/core/theme/app_colors.dart`
```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── 주요 퍼플 계열 ───────────────────────────────────
  static const primary        = Color(0xFF7C6AFA); // 메인 퍼플
  static const primaryLight   = Color(0xFFB3A7FD); // 연한 퍼플
  static const primaryDark    = Color(0xFF5A49D6); // 진한 퍼플

  // ── 배경 ─────────────────────────────────────────────
  static const background     = Color(0xFFF0EEE9); // 크림/베이지
  static const surface        = Color(0xFFFFFFFF); // 카드 배경
  static const surfaceVariant = Color(0xFFF5F3EF); // 연한 배경

  // ── 텍스트 ───────────────────────────────────────────
  static const textPrimary    = Color(0xFF1A1A2E); // 진한 텍스트
  static const textSecondary  = Color(0xFF6B6B8A); // 보조 텍스트
  static const textHint       = Color(0xFFAAAAAA); // 힌트 텍스트

  // ── 상태 색상 ─────────────────────────────────────────
  static const error          = Color(0xFFE53E3E);
  static const success        = Color(0xFF38A169);
  static const warning        = Color(0xFFD69E2E);

  // ── 구분선 / 테두리 ───────────────────────────────────
  static const divider        = Color(0xFFE8E6E1);
  static const border         = Color(0xFFD4D0C8);

  // ── 이벤트 마커 색상 팔레트 ──────────────────────────
  static const eventColors = [
    Color(0xFF7C6AFA), // 퍼플
    Color(0xFFFC8181), // 레드
    Color(0xFF68D391), // 그린
    Color(0xFF63B3ED), // 블루
    Color(0xFFF6AD55), // 오렌지
    Color(0xFFB794F4), // 라벤더
  ];

  // ── 그라디언트 ───────────────────────────────────────
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B86FD), Color(0xFF7C6AFA)],
  );
}
```

- [ ] **Step 4: AppTextStyles 생성**

파일: `lib/core/theme/app_text_styles.dart`
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );
  static const heading2 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );
  static const heading3 = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.4,
  );
  static const body1 = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );
  static const body2 = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );
  static const caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textHint, height: 1.4,
  );
  static const button = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: Colors.white, letterSpacing: 0.3,
  );
  static const label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}
```

- [ ] **Step 5: AppTheme 생성**

파일: `lib/core/theme/app_theme.dart`
```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: AppColors.surface,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppTextStyles.heading3,
      centerTitle: true,
    ),

    // NavigationBar (하단 탭)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryLight.withOpacity(0.3),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return const IconThemeData(color: AppColors.textHint, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTextStyles.label.copyWith(color: AppColors.primary);
        }
        return AppTextStyles.label;
      }),
      elevation: 4,
    ),

    // ElevatedButton (CaldyButton 대신 기본 버튼 기본값)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppTextStyles.button,
        elevation: 0,
      ),
    ),

    // OutlinedButton
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: AppColors.primary),
        textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
      ),
    ),

    // TextField / InputDecoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: AppTextStyles.body1.copyWith(color: AppColors.textHint),
    ),

    // Card
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      margin: EdgeInsets.zero,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),

    // FloatingActionButton
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // ProgressIndicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}
```

- [ ] **Step 6: main.dart에서 AppTheme 적용**

파일: `lib/main.dart` 수정 (theme: ThemeData(...) 부분만 교체)
```dart
import 'package:calddy/core/theme/app_theme.dart';
// ... 기존 imports 유지

// MaterialApp.router의 theme 파라미터를 교체:
theme: AppTheme.light,
// 기존 ThemeData(...) 블록 전체 삭제
```

- [ ] **Step 7: 빌드 확인**

```bash
flutter build apk --debug 2>&1 | head -20
```

Expected: `Running Gradle task 'assembleDebug'...` (오류 없음)

- [ ] **Step 8: 커밋**

```bash
cd D:\calddy
git add pubspec.yaml pubspec.lock lib/core/theme/ lib/main.dart
git commit -m "feat: add design system (AppColors, AppTextStyles, AppTheme) and missing packages"
```

---

## Task 2: 공용 위젯 컴포넌트 라이브러리

**목표:** 반복 사용되는 버튼, 카드, 빈 상태 위젯을 재사용 가능하게 분리

**Files:**
- Create: `lib/core/widgets/calddy_button.dart`
- Create: `lib/core/widgets/calddy_card.dart`
- Create: `lib/core/widgets/empty_state.dart`
- Create: `lib/core/widgets/calddy_avatar.dart`

- [ ] **Step 1: CaldyButton 생성**

파일: `lib/core/widgets/calddy_button.dart`
```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum CaldyButtonVariant { primary, secondary, outline, ghost }

class CaldyButton extends StatelessWidget {
  const CaldyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CaldyButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final CaldyButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label, style: _textStyle),
            ],
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: switch (variant) {
        CaldyButtonVariant.primary => ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: child,
          ),
        CaldyButtonVariant.secondary => ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight.withOpacity(0.3),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: child,
          ),
        CaldyButtonVariant.outline => OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: child,
          ),
        CaldyButtonVariant.ghost => TextButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
      },
    );
  }

  TextStyle get _textStyle => switch (variant) {
    CaldyButtonVariant.primary   => AppTextStyles.button,
    CaldyButtonVariant.secondary => AppTextStyles.button.copyWith(color: AppColors.primary),
    CaldyButtonVariant.outline   => AppTextStyles.button.copyWith(color: AppColors.primary),
    CaldyButtonVariant.ghost     => AppTextStyles.button.copyWith(color: AppColors.primary),
  };
}
```

- [ ] **Step 2: CaldyCard 생성**

파일: `lib/core/widgets/calddy_card.dart`
```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CaldyCard extends StatelessWidget {
  const CaldyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: EmptyState 위젯 생성**

파일: `lib/core/widgets/empty_state.dart`
```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.body2, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: CaldyAvatar 생성**

파일: `lib/core/widgets/calddy_avatar.dart`
```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CaldyAvatar extends StatelessWidget {
  const CaldyAvatar({
    super.key,
    this.imageUrl,
    this.nickname,
    this.radius = 24,
  });

  final String? imageUrl;
  final String? nickname;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: AppColors.primaryLight,
      );
    }
    final initial = (nickname?.isNotEmpty == true) ? nickname![0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight.withOpacity(0.4),
      child: Text(
        initial,
        style: AppTextStyles.heading3.copyWith(color: AppColors.primary),
      ),
    );
  }
}
```

- [ ] **Step 5: 커밋**

```bash
cd D:\calddy
git add lib/core/widgets/
git commit -m "feat: add shared UI components (CaldyButton, CaldyCard, EmptyState, CaldyAvatar)"
```

---

## Task 3: MainShell (하단 탭 네비게이션) 디자인 적용

**Files:**
- Modify: `lib/core/router/main_shell.dart`

- [ ] **Step 1: MainShell 디자인 적용**

파일: `lib/core/router/main_shell.dart` 전체 교체
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import 'app_routes.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    (icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: '캘린더', route: AppRoutes.home),
    (icon: Icons.dynamic_feed_outlined,   activeIcon: Icons.dynamic_feed,   label: '피드',   route: AppRoutes.feed),
    (icon: Icons.people_outline,          activeIcon: Icons.people,         label: '친구',   route: AppRoutes.friends),
    (icon: Icons.person_outline,          activeIcon: Icons.person,         label: '내 정보', route: AppRoutes.profile),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.feed))    return 1;
    if (location.startsWith(AppRoutes.friends)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) => context.go(_tabs[index].route),
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.primaryLight.withOpacity(0.25),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final tab in _tabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon, color: AppColors.primary),
                label: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 커밋**

```bash
cd D:\calddy
git add lib/core/router/main_shell.dart
git commit -m "feat: apply pastel purple design to bottom navigation shell"
```

---

## Task 4: LoginPage 디자인 적용

**Files:**
- Modify: `lib/features/auth/presentation/pages/login_page.dart`

- [ ] **Step 1: LoginPage Figma 디자인 적용**

파일: `lib/features/auth/presentation/pages/login_page.dart` 전체 교체
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/widgets/calddy_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_dialog.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isGoogleLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(signInWithGoogleUseCaseProvider).call(const NoParams());
    } on AuthFailure catch (e) {
      if (mounted) await AuthErrorDialog.show(context, e);
    } catch (_) {
      if (mounted) await AuthErrorDialog.show(context, const UnknownAuthFailure());
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── 로고 영역 ─────────────────────────────
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 52),
              ),
              const SizedBox(height: 20),
              Text('Calddy', style: AppTextStyles.heading1.copyWith(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                '친구와 함께하는 캘린더 관리',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // ── 버튼 영역 ─────────────────────────────
              CaldyButton(
                label: 'Google로 시작하기',
                isLoading: _isGoogleLoading,
                onPressed: _signInWithGoogle,
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  width: 20, height: 20,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.g_mobiledata, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              CaldyButton(
                label: '이메일로 시작하기',
                variant: CaldyButtonVariant.outline,
                onPressed: () => context.push(AppRoutes.loginEmail),
              ),

              const Spacer(),

              // ── 하단 안내 문구 ─────────────────────────
              Text(
                '로그인 시 이용약관 및 개인정보처리방침에 동의합니다.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
```

> **참고:** `assets/images/google_logo.png`가 없으면 `errorBuilder`가 fallback 아이콘을 보여주므로 빌드 에러 없음. 나중에 실제 Google 로고 추가.

- [ ] **Step 2: 커밋**

```bash
cd D:\calddy
git add lib/features/auth/presentation/pages/login_page.dart
git commit -m "feat: apply Figma design to LoginPage (pastel purple theme)"
```

---

## Task 5: CalendarPage — 스켈레톤 + 실제 Provider 연결

**목표:** `table_calendar` 을 사용하여 월별 달력 UI 구현, `calendarDataProvider` 에서 이벤트 로드

**Files:**
- Modify: `lib/features/calendar/presentation/pages/calendar_page.dart`
- Create: `lib/features/calendar/presentation/widgets/calendar_event_marker.dart`
- Create: `lib/features/calendar/presentation/widgets/event_bottom_sheet.dart`

- [ ] **Step 1: CalendarEventMarker 위젯 생성**

파일: `lib/features/calendar/presentation/widgets/calendar_event_marker.dart`
```dart
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class CalendarEventMarker extends StatelessWidget {
  const CalendarEventMarker({
    super.key,
    required this.color,
    this.size = 7,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
```

- [ ] **Step 2: EventBottomSheet 위젯 생성 (날짜 탭 시 이벤트 목록)**

파일: `lib/features/calendar/presentation/widgets/event_bottom_sheet.dart`
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/calddy_button.dart';
import '../../domain/entities/event_entity.dart';

class EventBottomSheet extends StatelessWidget {
  const EventBottomSheet({
    super.key,
    required this.date,
    required this.events,
    required this.onCreateEvent,
  });

  final DateTime date;
  final List<EventEntity> events;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${date.month}월 ${date.day}일',
                  style: AppTextStyles.heading3,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: onCreateEvent,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 이벤트 목록
          Flexible(
            child: events.isEmpty
                ? const EmptyState(
                    message: '이 날에는 일정이 없어요.',
                    icon: Icons.event_available_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _EventTile(event: events[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(event.color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 40,
            decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${_fmtTime(event.startAt)} ~ ${_fmtTime(event.endAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (event.status == EventStatus.done)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('완료', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
            ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Color _colorFromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}
```

- [ ] **Step 3: CalendarPage 전체 재구현**

파일: `lib/features/calendar/presentation/pages/calendar_page.dart` 전체 교체
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/calddy_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/event_entity.dart';
import '../providers/calendar_providers.dart';
import '../widgets/calendar_event_marker.dart';
import '../widgets/event_bottom_sheet.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  // 해당 날짜의 이벤트 목록 반환
  List<EventEntity> _eventsForDay(DateTime day, List<EventEntity>? events) {
    if (events == null) return [];
    return events.where((e) =>
      e.startAt.year == day.year &&
      e.startAt.month == day.month &&
      e.startAt.day == day.day,
    ).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay, List<EventEntity>? events) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    final dayEvents = _eventsForDay(selectedDay, events);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventBottomSheet(
        date: selectedDay,
        events: dayEvents,
        onCreateEvent: () {
          Navigator.pop(context);
          context.push(AppRoutes.eventCreate);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(calendarDataProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 헤더 ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
              child: Row(
                children: [
                  Text('Calddy', style: AppTextStyles.heading2.copyWith(color: AppColors.primary)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                    onPressed: () => context.push(AppRoutes.notifications),
                  ),
                  CaldyAvatar(
                    imageUrl: user?.avatarUrl,
                    nickname: user?.nickname,
                    radius: 18,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            // ── TableCalendar ───────────────────────────
            calendarAsync.when(
              loading: () => const _CalendarSkeleton(),
              error: (e, _) => _CalendarWidget(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                events: const [],
                onDaySelected: (d, f) => _onDaySelected(d, f, const []),
                onPageChanged: (d) {
                  ref.read(selectedMonthProvider.notifier).state =
                      DateTime(d.year, d.month);
                  setState(() => _focusedDay = d);
                },
              ),
              data: (data) => _CalendarWidget(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                events: data.events,
                onDaySelected: (d, f) => _onDaySelected(d, f, data.events),
                onPageChanged: (d) {
                  ref.read(selectedMonthProvider.notifier).state =
                      DateTime(d.year, d.month);
                  setState(() => _focusedDay = d);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.eventCreate),
        icon: const Icon(Icons.add),
        label: const Text('일정 추가'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ── 달력 위젯 (로드 완료 상태) ────────────────────────────
class _CalendarWidget extends StatelessWidget {
  const _CalendarWidget({
    required this.focusedDay,
    required this.selectedDay,
    required this.events,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<EventEntity> events;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;

  @override
  Widget build(BuildContext context) {
    return TableCalendar<EventEntity>(
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      focusedDay: focusedDay,
      selectedDayPredicate: (d) => isSameDay(d, selectedDay),
      eventLoader: (day) => events.where((e) =>
        e.startAt.year == day.year &&
        e.startAt.month == day.month &&
        e.startAt.day == day.day,
      ).toList(),
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: '월'},
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      locale: 'ko_KR',
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: AppTextStyles.heading3,
        leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textSecondary),
        rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: AppTextStyles.body1,
        weekendTextStyle: AppTextStyles.body1.copyWith(color: AppColors.error.withOpacity(0.8)),
        todayDecoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        todayTextStyle: AppTextStyles.body1.copyWith(
          color: AppColors.primary, fontWeight: FontWeight.w700,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: AppTextStyles.body1.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        markerSize: 6,
        markersMaxCount: 3,
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, dayEvents) {
          if (dayEvents.isEmpty) return null;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: dayEvents.take(3).map((e) {
              Color c;
              try {
                c = Color(int.parse(e.color.replaceFirst('#', '0xFF')));
              } catch (_) {
                c = AppColors.primary;
              }
              return CalendarEventMarker(color: c);
            }).toList(),
          );
        },
      ),
    );
  }
}

// ── 로딩 중 스켈레톤 ─────────────────────────────────────
class _CalendarSkeleton extends StatelessWidget {
  const _CalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmer(width: 80, height: 20),
              _shimmer(width: 40, height: 20),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            children: List.generate(35, (_) => Padding(
              padding: const EdgeInsets.all(4),
              child: _shimmer(width: 36, height: 36, radius: 18),
            )),
          ),
        ],
      ),
    );
  }

  Widget _shimmer({required double width, required double height, double radius = 4}) =>
      Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
```

- [ ] **Step 4: app_routes.dart에 eventCreate 경로 상수 확인**

`lib/core/router/app_routes.dart` 파일에서 `eventCreate` 상수 확인:
```bash
grep -n "eventCreate" D:\calddy\lib\core\router\app_routes.dart
```

없으면 추가:
```dart
static const String eventCreate = '/home/event/create';
```

- [ ] **Step 5: 커밋**

```bash
cd D:\calddy
git add lib/features/calendar/
git commit -m "feat: implement CalendarPage with table_calendar and Riverpod provider connection"
```

---

## Task 6: EventCreatePage + EventDetailPage 스켈레톤

**Files:**
- Create: `lib/features/calendar/presentation/pages/event_create_page.dart`
- Create: `lib/features/calendar/presentation/pages/event_detail_page.dart`
- Modify: `lib/core/router/app_router.dart` (PlaceholderPage → 실제 페이지로 교체)

- [ ] **Step 1: EventCreatePage 스켈레톤 생성**

파일: `lib/features/calendar/presentation/pages/event_create_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/calddy_button.dart';
import '../../domain/usecases/create_event_usecase.dart';
import '../providers/calendar_providers.dart';

class EventCreatePage extends ConsumerStatefulWidget {
  const EventCreatePage({super.key});

  @override
  ConsumerState<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends ConsumerState<EventCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  DateTime _startAt = DateTime.now().copyWith(minute: 0, second: 0);
  DateTime _endAt = DateTime.now().copyWith(minute: 0, second: 0).add(const Duration(hours: 1));
  String _color = '#7C6AFA';
  bool _isLoading = false;

  static const _colorOptions = [
    '#7C6AFA', '#FC8181', '#68D391', '#63B3ED', '#F6AD55', '#B794F4',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // CreateEventParams는 EventEntity를 통째로 받음
      // id, userId, createdAt은 DB 서버에서 생성되지만 임시값 필요 (DataSource에서 덮어씀)
      final now = DateTime.now();
      await ref.read(createEventUseCaseProvider).call(CreateEventParams(
        event: EventEntity(
          id: '',
          userId: '',
          title: _titleCtrl.text.trim(),
          location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
          startAt: _startAt,
          endAt: _endAt,
          color: _color,
          isDday: false,
          memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
          status: EventStatus.pending,
          visibility: EventVisibility.public,
          createdAt: now,
        ),
      ));
      ref.invalidate(calendarDataProvider);
      if (mounted) context.pop();
    } on CalendarFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('일정을 만드는 데 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('일정 만들기'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 제목
            _SectionLabel(label: '제목'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: '일정 이름을 입력하세요'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
              style: AppTextStyles.body1,
            ),
            const SizedBox(height: 20),

            // 시작 시간
            _SectionLabel(label: '시작'),
            const SizedBox(height: 8),
            _DateTimePicker(
              value: _startAt,
              onChanged: (dt) => setState(() => _startAt = dt),
            ),
            const SizedBox(height: 16),

            // 종료 시간
            _SectionLabel(label: '종료'),
            const SizedBox(height: 8),
            _DateTimePicker(
              value: _endAt,
              onChanged: (dt) => setState(() => _endAt = dt),
            ),
            const SizedBox(height: 20),

            // 색상 선택
            _SectionLabel(label: '색상'),
            const SizedBox(height: 8),
            Row(
              children: _colorOptions.map((hex) {
                final c = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                final isSelected = _color == hex;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36, height: 36,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 장소
            _SectionLabel(label: '장소 (선택)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                hintText: '장소를 입력하세요',
                prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textHint),
              ),
            ),
            const SizedBox(height: 20),

            // 메모
            _SectionLabel(label: '메모 (선택)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _memoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: '메모를 입력하세요'),
            ),
            const SizedBox(height: 32),

            CaldyButton(label: '일정 저장', onPressed: _submit, isLoading: _isLoading),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600));
  }
}

class _DateTimePicker extends StatelessWidget {
  const _DateTimePicker({required this.value, required this.onChanged});
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (time == null) return;
        onChanged(date.copyWith(hour: time.hour, minute: time.minute));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textHint),
            const SizedBox(width: 10),
            Text(
              DateFormat('yyyy년 MM월 dd일  HH:mm').format(value),
              style: AppTextStyles.body1,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: EventDetailPage 스켈레톤 생성**

파일: `lib/features/calendar/presentation/pages/event_detail_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/calddy_button.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/delete_event_usecase.dart';
import '../../domain/usecases/complete_event_usecase.dart';
import '../providers/calendar_providers.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({super.key, required this.eventId});
  final String eventId;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  bool _isLoading = false;

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('일정 삭제'),
        content: const Text('이 일정을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(deleteEventUseCaseProvider).call(DeleteEventParams(eventId: widget.eventId));
      ref.invalidate(calendarDataProvider);
      if (mounted) context.pop();
    } on CalendarFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('삭제에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    // calendarDataProvider에서 eventId로 이벤트 찾기
    final calendarAsync = ref.watch(calendarDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('일정 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _isLoading ? null : _deleteEvent,
          ),
        ],
      ),
      body: calendarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is CalendarFailure ? e.message : '불러오기 실패')),
        data: (data) {
          final event = data.events.where((e) => e.id == widget.eventId).firstOrNull;
          if (event == null) return const Center(child: Text('일정을 찾을 수 없습니다.'));
          return _EventDetailBody(event: event);
        },
      ),
    );
  }
}

class _EventDetailBody extends StatelessWidget {
  const _EventDetailBody({required this.event});
  final EventEntity event;

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(event.color);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 컬러 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(height: 12),
                Text(event.title, style: AppTextStyles.heading2),
                if (event.memo != null) ...[
                  const SizedBox(height: 8),
                  Text(event.memo!, style: AppTextStyles.body2),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InfoRow(icon: Icons.access_time, label: '시작', value: _fmtDateTime(event.startAt)),
          _InfoRow(icon: Icons.access_time_filled, label: '종료', value: _fmtDateTime(event.endAt)),
          if (event.location != null)
            _InfoRow(icon: Icons.location_on_outlined, label: '장소', value: event.location!),
          _InfoRow(
            icon: event.status == EventStatus.done ? Icons.check_circle : Icons.radio_button_unchecked,
            label: '상태',
            value: event.status == EventStatus.done ? '완료' : '예정',
            valueColor: event.status == EventStatus.done ? AppColors.success : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  String _fmtDateTime(DateTime dt) =>
      DateFormat('yyyy년 MM월 dd일 HH:mm').format(dt);

  Color _colorFromHex(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xFF'))); }
    catch (_) { return AppColors.primary; }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textHint),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.body2),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body1.copyWith(color: valueColor),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: app_router.dart에서 PlaceholderPage → 실제 페이지로 교체**

`lib/core/router/app_router.dart` import 추가:
```dart
import '../../features/calendar/presentation/pages/event_create_page.dart';
import '../../features/calendar/presentation/pages/event_detail_page.dart';
```

라우터 내 Calendar 라우트 교체:
```dart
GoRoute(
  path: 'event/create',
  builder: (_, _) => const EventCreatePage(),  // _PlaceholderPage 교체
),
GoRoute(
  path: 'event/:eventId',
  builder: (_, s) => EventDetailPage(eventId: s.pathParameters['eventId']!),  // _PlaceholderPage 교체
),
```

- [ ] **Step 4: 커밋**

```bash
cd D:\calddy
git add lib/features/calendar/presentation/pages/event_create_page.dart \
        lib/features/calendar/presentation/pages/event_detail_page.dart \
        lib/core/router/app_router.dart
git commit -m "feat: add EventCreatePage and EventDetailPage with Figma design"
```

---

## Task 7: FeedPage UI 개선

**Files:**
- Modify: `lib/features/feed/presentation/pages/feed_page.dart`

- [ ] **Step 1: FeedPage 카드 UI로 전면 개선**

파일: `lib/features/feed/presentation/pages/feed_page.dart` 전체 교체 (핵심 부분)

`_PostTile`을 카드 형식으로 교체:
```dart
// ... 기존 import 유지, 아래 import 추가
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/calddy_card.dart';
import '../../../../core/widgets/calddy_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
```

`_PostTile` 클래스 전체 교체:
```dart
class _PostTile extends StatelessWidget {
  const _PostTile({
    required this.post,
    required this.onDelete,
    required this.onToggleLike,
    required this.onTap,
  });

  final PostEntity post;
  final VoidCallback onDelete;
  final VoidCallback onToggleLike;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CaldyCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 아바타 + 닉네임 + 시간
          Row(
            children: [
              CaldyAvatar(radius: 18, nickname: post.userId.substring(0, 2)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.userId.substring(0, 8), style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
                    Text(_fmt(post.createdAt), style: AppTextStyles.caption),
                  ],
                ),
              ),
              Icon(
                post.visibility == PostVisibility.public ? Icons.public : Icons.lock_outline,
                size: 16,
                color: AppColors.textHint,
              ),
            ],
          ),

          // 내용
          if (post.content != null) ...[
            const SizedBox(height: 12),
            Text(post.content!, style: AppTextStyles.body1),
          ],

          // 이미지
          if (post.imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.image_outlined, color: AppColors.textHint, size: 48),
                ),
              ),
            ),
          ],

          // 하단: 좋아요 + 삭제
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: onToggleLike,
                child: Row(
                  children: [
                    Icon(
                      post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                      color: post.isLikedByMe ? AppColors.error : AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.likesCount}', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline, size: 18, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${dt.month}/${dt.day}';
  }
}
```

`EmptyState` 사용으로 교체 (data가 비어있을 때):
```dart
// posts.isEmpty 분기 교체
return const EmptyState(
  message: '이 날의 게시글이 없습니다.',
  icon: Icons.dynamic_feed_outlined,
);
```

- [ ] **Step 2: 커밋**

```bash
cd D:\calddy
git add lib/features/feed/presentation/pages/feed_page.dart
git commit -m "feat: redesign FeedPage with card UI and improved post tiles"
```

---

## Task 8: ProfilePage + EditProfilePage + SettingsPage 스켈레톤

**Files:**
- Modify: `lib/features/user/presentation/pages/profile_page.dart`
- Create: `lib/features/user/presentation/pages/edit_profile_page.dart`
- Create: `lib/features/user/presentation/pages/settings_page.dart`
- Modify: `lib/core/router/app_router.dart` (PlaceholderPage 교체)

- [ ] **Step 1: ProfilePage 구현**

파일: `lib/features/user/presentation/pages/profile_page.dart` 전체 교체
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/calddy_avatar.dart';
import '../../../../core/widgets/calddy_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/usecases/sign_out_use_case.dart';
import '../../../../core/usecase/usecase.dart';
import '../providers/user_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            // 프로필 헤더
            CaldyCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CaldyAvatar(imageUrl: user?.avatarUrl, nickname: user?.nickname, radius: 40),
                  const SizedBox(height: 12),
                  Text(
                    user?.nickname ?? '닉네임 없음',
                    style: AppTextStyles.heading2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: AppTextStyles.body2,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.editProfile),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(160, 40),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('프로필 편집', style: AppTextStyles.body2.copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 메뉴 목록
            CaldyCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: '알림',
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: '설정',
                    onTap: () => context.push(AppRoutes.settings),
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.logout,
                    label: '로그아웃',
                    labelColor: AppColors.error,
                    onTap: () async {
                      await ref.read(signOutUseCaseProvider).call(const NoParams());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.labelColor});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: labelColor ?? AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.body1.copyWith(color: labelColor)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 2: EditProfilePage 스켈레톤 생성**

파일: `lib/features/user/presentation/pages/edit_profile_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/calddy_avatar.dart';
import '../../../../core/widgets/calddy_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/user_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nicknameCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nicknameCtrl = TextEditingController(text: user?.nickname ?? '');
  }

  @override
  void dispose() { _nicknameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    // TODO: updateProfileUseCaseProvider 연결
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) { setState(() => _isLoading = false); context.pop(); }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('프로필 편집')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Stack(
              children: [
                CaldyAvatar(imageUrl: user?.avatarUrl, nickname: user?.nickname, radius: 52),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(labelText: '닉네임'),
              style: AppTextStyles.body1,
            ),
            const Spacer(),
            CaldyButton(label: '저장', onPressed: _save, isLoading: _isLoading),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: SettingsPage 스켈레톤 생성**

파일: `lib/features/user/presentation/pages/settings_page.dart`
```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/calddy_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CaldyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('푸시 알림', style: AppTextStyles.body1),
                  subtitle: Text('새 알림을 받습니다', style: AppTextStyles.caption),
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text('계정 삭제', style: AppTextStyles.body1.copyWith(color: AppColors.error)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: app_router.dart PlaceholderPage 교체**

import 추가 + 라우트 교체:
```dart
import '../../features/user/presentation/pages/edit_profile_page.dart';
import '../../features/user/presentation/pages/settings_page.dart';

// profile 하위 라우트 교체:
GoRoute(path: 'edit',     builder: (_, _) => const EditProfilePage()),
GoRoute(path: 'settings', builder: (_, _) => const SettingsPage()),
```

- [ ] **Step 5: 커밋**

```bash
cd D:\calddy
git add lib/features/user/ lib/core/router/app_router.dart
git commit -m "feat: implement ProfilePage, EditProfilePage, SettingsPage with design"
```

---

## Task 9: NotificationsPage 스켈레톤

**Files:**
- Modify: `lib/features/notification/presentation/pages/notifications_page.dart`

- [ ] **Step 1: NotificationsPage Provider 연결 + UI 구현**

파일: `lib/features/notification/presentation/pages/notifications_page.dart` 전체 교체
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/calddy_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          TextButton(
            onPressed: () => ref.invalidate(notificationsProvider),
            child: Text('모두 읽기', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(message: '알림을 불러오지 못했습니다.', icon: Icons.error_outline),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(
              message: '새로운 알림이 없습니다.',
              icon: Icons.notifications_none_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _NotificationTile(notification: notifications[i]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});
  final NotificationEntity notification;

  @override
  Widget build(BuildContext context) {
    return CaldyCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: notification.isRead
                  ? AppColors.surfaceVariant
                  : AppColors.primaryLight.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(_typeIcon(notification.type), color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(notification.body, style: AppTextStyles.body2, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  IconData _typeIcon(NotificationType type) => switch (type) {
    NotificationType.friendRequest     => Icons.person_add_outlined,
    NotificationType.appointmentInvite => Icons.event_outlined,
    NotificationType.postLiked         => Icons.favorite_outline,
    NotificationType.postCommented     => Icons.chat_bubble_outline,
    _                                  => Icons.notifications_outlined,
  };
}
```

- [ ] **Step 2: notificationsProvider 확인 및 필요시 추가**

```bash
grep -n "notificationsProvider" D:\calddy\lib\features\notification\presentation\providers\notification_providers.dart
```

없으면 `notification_providers.dart` 에 추가:
```dart
final notificationsProvider = FutureProvider.autoDispose<List<NotificationEntity>>((ref) {
  return ref.read(getNotificationsUseCaseProvider).call(const NoParams());
});
```

- [ ] **Step 3: 커밋**

```bash
cd D:\calddy
git add lib/features/notification/
git commit -m "feat: implement NotificationsPage with real provider connection"
```

---

## Task 10: AppointmentCreatePage + AppointmentDetailPage 스켈레톤

**Files:**
- Create: `lib/features/appointment/presentation/pages/appointment_create_page.dart`
- Create: `lib/features/appointment/presentation/pages/appointment_detail_page.dart`
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1: AppointmentCreatePage 스켈레톤**

파일: `lib/features/appointment/presentation/pages/appointment_create_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/calddy_button.dart';
import '../../../friend/presentation/providers/friend_providers.dart';
import '../providers/appointment_providers.dart';
import '../../domain/usecases/create_appointment_use_case.dart';
import '../../../../core/error/failures.dart';

class AppointmentCreatePage extends ConsumerStatefulWidget {
  const AppointmentCreatePage({super.key});

  @override
  ConsumerState<AppointmentCreatePage> createState() => _AppointmentCreatePageState();
}

class _AppointmentCreatePageState extends ConsumerState<AppointmentCreatePage> {
  final _titleCtrl = TextEditingController();
  final _selectedFriendIds = <String>[];
  bool _isLoading = false;

  @override
  void dispose() { _titleCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 최소 1명의 친구를 선택해주세요.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // TODO: eventId 연동 (현재는 임시로 약속 생성 흐름만 구현)
      if (mounted) context.pop();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약속 만들기에 실패했습니다.'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider(FriendSortType.alphabetical));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('약속 만들기')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('제목', style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(controller: _titleCtrl, decoration: const InputDecoration(hintText: '약속 이름')),
          const SizedBox(height: 24),
          Text('친구 선택', style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          friendsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('친구 목록을 불러오지 못했습니다.'),
            data: (friends) => Column(
              children: friends.map((f) => CheckboxListTile(
                title: Text(f.friendId, style: AppTextStyles.body1),
                value: _selectedFriendIds.contains(f.friendId),
                activeColor: AppColors.primary,
                onChanged: (v) {
                  setState(() {
                    if (v == true) _selectedFriendIds.add(f.friendId);
                    else _selectedFriendIds.remove(f.friendId);
                  });
                },
              )).toList(),
            ),
          ),
          const SizedBox(height: 32),
          CaldyButton(label: '약속 보내기', onPressed: _submit, isLoading: _isLoading),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: AppointmentDetailPage 스켈레톤**

파일: `lib/features/appointment/presentation/pages/appointment_detail_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/calddy_card.dart';
import '../../../../core/widgets/calddy_button.dart';
import '../providers/appointment_providers.dart';
import '../../domain/usecases/accept_invite_use_case.dart';
import '../../domain/usecases/reject_invite_use_case.dart';

class AppointmentDetailPage extends ConsumerStatefulWidget {
  const AppointmentDetailPage({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  ConsumerState<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends ConsumerState<AppointmentDetailPage> {
  bool _isLoading = false;

  Future<void> _accept() async {
    setState(() => _isLoading = true);
    try {
      final invite = ref.read(myInvitesProvider).valueOrNull
          ?.where((i) => i.appointmentId == widget.appointmentId)
          .firstOrNull;
      if (invite == null) return;
      await ref.read(acceptInviteUseCaseProvider).call(AcceptInviteParams(inviteId: invite.id));
      ref.invalidate(myInvitesProvider);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isLoading = true);
    try {
      final invite = ref.read(myInvitesProvider).valueOrNull
          ?.where((i) => i.appointmentId == widget.appointmentId)
          .firstOrNull;
      if (invite == null) return;
      await ref.read(rejectInviteUseCaseProvider).call(RejectInviteParams(inviteId: invite.id));
      ref.invalidate(myInvitesProvider);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // appointmentDetailProvider — appointment_providers.dart에 정의된 실제 이름
    final appointmentAsync = ref.watch(appointmentDetailProvider(widget.appointmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('약속 상세')),
      body: appointmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('약속 정보를 불러오지 못했습니다.')),
        data: (appointment) {
          if (appointment == null) return const Center(child: Text('약속을 찾을 수 없습니다.'));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CaldyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('약속 정보', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Text('ID: ${appointment.id}', style: AppTextStyles.body2),
                    if (appointment.suggestedPlace != null)
                      Text('추천 장소: ${appointment.suggestedPlace}', style: AppTextStyles.body1),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CaldyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('초대 현황', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    ...appointment.invites.map((inv) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(inv.inviteeId, style: AppTextStyles.body1),
                          const Spacer(),
                          Text(inv.status.name, style: AppTextStyles.caption),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CaldyButton(
                      label: '거절',
                      variant: CaldyButtonVariant.outline,
                      onPressed: _isLoading ? null : _reject,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CaldyButton(
                      label: '수락',
                      onPressed: _isLoading ? null : _accept,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: app_router.dart Appointment PlaceholderPage 교체**

```dart
import '../../features/appointment/presentation/pages/appointment_create_page.dart';
import '../../features/appointment/presentation/pages/appointment_detail_page.dart';

// Calendar 하위 라우트 교체:
GoRoute(path: 'appointment/create', builder: (_, _) => const AppointmentCreatePage()),
GoRoute(path: 'appointment/:appointmentId', builder: (_, s) => AppointmentDetailPage(appointmentId: s.pathParameters['appointmentId']!)),
```

- [ ] **Step 4: 커밋**

```bash
cd D:\calddy
git add lib/features/appointment/ lib/core/router/app_router.dart
git commit -m "feat: add AppointmentCreatePage and AppointmentDetailPage skeletons"
```

---

## Task 11: DrawingPage 스켈레톤 (perfect_freehand)

**Files:**
- Create: `lib/features/calendar/presentation/pages/drawing_page.dart`
- Modify: `lib/core/router/app_router.dart`

- [ ] **Step 1: DrawingPage 구현**

파일: `lib/features/calendar/presentation/pages/drawing_page.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/calddy_button.dart';
import '../../domain/entities/drawing_entity.dart';
import '../../domain/usecases/save_drawing_usecase.dart';
import '../providers/calendar_providers.dart';

class DrawingPage extends ConsumerStatefulWidget {
  const DrawingPage({super.key, required this.date});
  final String date; // 'yyyy-MM-dd' 형식

  @override
  ConsumerState<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends ConsumerState<DrawingPage> {
  final List<DrawingStroke> _strokes = [];
  List<List<double>>? _currentPoints;
  Color _selectedColor = AppColors.primary;
  double _strokeWidth = 4.0;
  bool _isLoading = false;

  static const _colors = [
    AppColors.primary,
    Colors.black,
    AppColors.error,
    AppColors.success,
    Colors.orange,
    Colors.white,
  ];

  DateTime get _date {
    final parts = widget.date.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      // SaveDrawingParams는 DrawingEntity를 통째로 받음
      await ref.read(saveDrawingUseCaseProvider).call(SaveDrawingParams(
        drawing: DrawingEntity(
          id: '',
          userId: '',
          drawDate: _date,
          strokes: _strokes,
          updatedAt: DateTime.now(),
        ),
      ));
      if (mounted) context.pop();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했습니다.'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('${_date.month}월 ${_date.day}일 드로잉', style: AppTextStyles.heading3),
        actions: [
          TextButton(onPressed: () => setState(() => _strokes.clear()), child: const Text('초기화')),
          const SizedBox(width: 8),
          CaldyButton(
            label: '저장',
            isLoading: _isLoading,
            onPressed: _save,
            width: 80,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // 그리기 캔버스
          Expanded(
            child: GestureDetector(
              onPanStart: (d) {
                setState(() {
                  _currentPoints = [[d.localPosition.dx, d.localPosition.dy, 0.5]];
                });
              },
              onPanUpdate: (d) {
                setState(() {
                  _currentPoints = [
                    ..._currentPoints ?? [],
                    [d.localPosition.dx, d.localPosition.dy, 0.5],
                  ];
                });
              },
              onPanEnd: (_) {
                if (_currentPoints != null && _currentPoints!.isNotEmpty) {
                  setState(() {
                    _strokes.add(DrawingStroke(
                      color: '#${_selectedColor.value.toRadixString(16).padLeft(8, '0')}',
                      width: _strokeWidth,
                      points: _currentPoints!,
                    ));
                    _currentPoints = null;
                  });
                }
              },
              child: CustomPaint(
                painter: _DrawingPainter(
                  strokes: _strokes,
                  currentPoints: _currentPoints,
                  currentColor: _selectedColor,
                  currentWidth: _strokeWidth,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // 하단 도구 모음
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                // 색상 선택
                for (final c in _colors)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 32, height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: _selectedColor == c
                            ? Border.all(color: AppColors.primary, width: 3)
                            : Border.all(color: AppColors.border),
                      ),
                    ),
                  ),

                const Spacer(),

                // 굵기 슬라이더
                const Icon(Icons.line_weight, color: AppColors.textHint, size: 20),
                Slider(
                  value: _strokeWidth,
                  min: 2, max: 16,
                  onChanged: (v) => setState(() => _strokeWidth = v),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  const _DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  final List<DrawingStroke> strokes;
  final List<List<double>>? currentPoints;
  final Color currentColor;
  final double currentWidth;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.width);
    }
    if (currentPoints != null && currentPoints!.isNotEmpty) {
      final hex = '#${currentColor.value.toRadixString(16).padLeft(8, '0')}';
      _drawStroke(canvas, currentPoints!, hex, currentWidth);
    }
  }

  void _drawStroke(Canvas canvas, List<List<double>> points, String colorHex, double width) {
    if (points.isEmpty) return;
    Color c;
    try { c = Color(int.parse(colorHex.replaceFirst('#', '0xFF'))); }
    catch (_) { c = AppColors.primary; }

    final outlinePoints = getStroke(
      points.map((p) => PointVector(p[0], p[1], p.length > 2 ? p[2] : 0.5)).toList(),
      options: StrokeOptions(size: width, thinning: 0.5, smoothing: 0.5),
    );

    if (outlinePoints.isEmpty) return;
    final path = Path()..moveTo(outlinePoints[0].x, outlinePoints[0].y);
    for (final pt in outlinePoints) { path.lineTo(pt.x, pt.y); }
    path.close();

    canvas.drawPath(path, Paint()..color = c..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_DrawingPainter old) => true;
}
```

- [ ] **Step 2: app_router.dart drawing 라우트 교체**

```dart
import '../../features/calendar/presentation/pages/drawing_page.dart';

GoRoute(
  path: 'drawing/:date',
  builder: (_, s) => DrawingPage(date: s.pathParameters['date']!),
),
```

- [ ] **Step 3: 커밋**

```bash
cd D:\calddy
git add lib/features/calendar/presentation/pages/drawing_page.dart lib/core/router/app_router.dart
git commit -m "feat: add DrawingPage with perfect_freehand canvas"
```

---

## Task 12: 전체 빌드 검증 + git 브랜치 정리

**Files:**
- 없음 (검증만)

- [ ] **Step 1: 새 브랜치 생성 (작업 시작 전 해야 했다면 지금)**

```bash
cd D:\calddy
git checkout -b feat/frontend-ui
```

이미 분기됐다면 skip.

- [ ] **Step 2: 전체 flutter analyze**

```bash
flutter analyze 2>&1
```

Expected: `No issues found!` 또는 warning만 (error 없어야 함)

에러 있으면 → import 경로 또는 타입 불일치 수정.

- [ ] **Step 3: APK 디버그 빌드 확인**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 4: 최종 커밋**

```bash
cd D:\calddy
git add -A
git commit -m "feat: complete frontend skeleton UI for all domains"
```

---

## 구현 완료 체크리스트

| 도메인 | 페이지 | 스켈레톤 | Provider 연결 | 디자인 |
|--------|--------|---------|-------------|--------|
| 공통 | AppTheme, 공용 위젯 | ✅ Task 1-2 | — | ✅ |
| Shell | MainShell (하단 탭) | ✅ Task 3 | ✅ | ✅ |
| Auth | LoginPage | ✅ Task 4 | ✅ | ✅ |
| Calendar | CalendarPage | ✅ Task 5 | ✅ calendarDataProvider | ✅ |
| Calendar | EventCreatePage | ✅ Task 6 | ✅ createEventUseCaseProvider | ✅ |
| Calendar | EventDetailPage | ✅ Task 6 | ✅ calendarDataProvider | ✅ |
| Calendar | DrawingPage | ✅ Task 11 | ✅ saveDrawingUseCaseProvider | ✅ |
| Feed | FeedPage | ✅ Task 7 | ✅ feedByDateProvider | ✅ |
| User | ProfilePage | ✅ Task 8 | ✅ currentUserProvider | ✅ |
| User | EditProfilePage | ✅ Task 8 | 연결 준비됨 | ✅ |
| User | SettingsPage | ✅ Task 8 | — | ✅ |
| Notification | NotificationsPage | ✅ Task 9 | ✅ notificationsProvider | ✅ |
| Appointment | AppointmentCreatePage | ✅ Task 10 | ✅ friendsProvider | ✅ |
| Appointment | AppointmentDetailPage | ✅ Task 10 | ✅ appointmentProvider | ✅ |

---

## 주의사항 (아키텍처 규칙)

> **절대 어기면 안 되는 규칙 요약**
> - `presentation/` 에서 `Supabase.instance.client` 직접 호출 금지
> - `domain/` 에서 `supabase`, `flutter` package import 금지
> - FutureProvider 내부에서는 `ref.read` (ref.watch 금지)
> - 경로 문자열은 `AppRoutes` 상수만 사용, 하드코딩 금지
> - 테이블명은 `SupabaseConstants` 상수 사용

