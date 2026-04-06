import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../providers/auth_providers.dart';
import 'login_page.dart';
import 'onboarding_page.dart'; // 곧 생성할 페이지

/// 앱 진입 시 세션 확인 및 초기화를 담당하는 스플래시 페이지
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 인증 상태를 구독하여 상태가 로드될 때까지 기다림
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }
        
        // 로그인 됨 -> 온보딩 여부에 따라 화면 분기
        if (user.isOnboarded) {
          return const CalendarPage();
        } else {
          return const OnboardingPage();
        }
      },
      loading: () => const _SplashLoadingView(),
      // 스트림 에러 발생 시 로그인 페이지로 안전하게 fallback
      error: (e, _) => const LoginPage(),
    );
  }
}

class _SplashLoadingView extends StatelessWidget {
  const _SplashLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_rounded, size: 80, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text(
              'Calddy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
