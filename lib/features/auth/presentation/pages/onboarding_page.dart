import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../domain/value_objects/nickname.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_dialog.dart';

/// 닉네임 설정 등 초기 온보딩 화면
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  bool _isSigningOut = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final nickname = _nicknameController.text.trim();

    // 도메인 Value Object로 닉네임 형식 검증
    final validationError = Nickname.validate(nickname);
    if (validationError != null) {
      if (mounted) await AuthErrorDialog.show(context, validationError);
      return;
    }

    // authStateProvider가 로딩 중이거나 유저가 없으면 진행 불가
    // (SplashPage에서 라우팅하므로 정상 상황에서는 발생하지 않음)
    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) {
      if (mounted) {
        await AuthErrorDialog.show(context, const UnknownAuthFailure());
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(completeOnboardingUseCaseProvider).call(
            nickname: nickname,
          );
    } on AuthFailure catch (e) {
      if (mounted) await AuthErrorDialog.show(context, e);
    } catch (_) {
      if (mounted) await AuthErrorDialog.show(context, const UnknownAuthFailure());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await ref.read(signOutUseCaseProvider)();
    } on AuthFailure catch (e) {
      if (mounted) await AuthErrorDialog.show(context, e);
    } catch (_) {
      if (mounted) await AuthErrorDialog.show(context, const UnknownAuthFailure());
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool anyLoading = _isLoading || _isSigningOut;

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
                hintText: '한글, 영문, 숫자, _, - 사용 가능',
                helperText: '2~20자, 공백 불가',
              ),
              maxLength: 20,
              enabled: !anyLoading,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: anyLoading ? null : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('시작하기'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: anyLoading ? null : _signOut,
              child: _isSigningOut
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
