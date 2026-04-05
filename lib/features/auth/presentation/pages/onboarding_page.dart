import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/global_providers.dart';
import '../providers/auth_providers.dart';

/// 닉네임 설정 등 초기 온보딩 화면
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// 닉네임 저장 및 온보딩 완료 처리
  Future<void> _completeOnboarding() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final user = ref.read(currentUserProvider);

      if (user == null) return;

      // profiles 테이블 업데이트
      await supabase.from('profiles').update({
        'nickname': nickname,
        'is_onboarded': true,
      }).eq('id', user.id);

      // auth 세션 refresh → authStateChanges 스트림 재트리거
      // profiles 업데이트는 onAuthStateChange를 자동 트리거하지 않으므로 수동 refresh
      await supabase.auth.refreshSession();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('설정 실패: 중복된 닉네임이거나 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('초기 설정')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '환영합니다!\n사용하실 닉네임을 설정해주세요.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
                hintText: '다른 사용자와 중복되지 않는 닉네임',
              ),
              maxLength: 20,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('시작하기'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.read(signOutUseCaseProvider)(),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
