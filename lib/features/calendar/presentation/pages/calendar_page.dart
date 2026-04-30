import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// 메인 캘린더 화면
class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calddy'),
        actions: [
          IconButton(
            onPressed: () => ref
                .read(signOutUseCaseProvider)
                .call(const NoParams()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user?.avatarUrl != null)
              CircleAvatar(
                backgroundImage: NetworkImage(user!.avatarUrl!),
                radius: 40,
              ),
            const SizedBox(height: 16),
            Text('${user?.nickname ?? '사용자'}님, 환영합니다!'),
            const SizedBox(height: 8),
            const Text('현재 캘린더 준비 중입니다.'),
          ],
        ),
      ),
    );
  }
}
