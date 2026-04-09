import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';

/// 네트워크 오류 등으로 인증 상태 로딩에 실패했을 때 표시되는 페이지.
/// "다시 시도" 버튼으로 authStateProvider를 재구독하여 복구를 시도한다.
/// UI 디자인은 추후 프론트엔드에서 개선 예정.
class NetworkErrorPage extends ConsumerWidget {
  const NetworkErrorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '네트워크 연결을 확인해주세요',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(authStateProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
