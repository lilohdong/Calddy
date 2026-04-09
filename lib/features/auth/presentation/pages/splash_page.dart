import 'package:flutter/material.dart';

/// 앱 초기 로딩 중에 표시되는 스플래시 페이지.
/// 인증 상태에 따른 라우팅은 app_router.dart의 redirect에서 처리한다.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

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
