import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_dialog.dart';

/// 비밀번호 재설정 이메일 전송 페이지
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    // 이메일 형식 검증 → 오류 시 모달
    final emailValid = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email);
    if (!emailValid) {
      if (mounted) await AuthErrorDialog.show(context, const EmailValidationFailure());
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(sendPasswordResetEmailUseCaseProvider).call(email);

      // Supabase는 이메일 존재 여부와 무관하게 성공을 반환한다 (유저 열거 방지).
      // 항상 동일한 안내 메시지를 표시한다.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('재설정 링크를 전송했습니다. 이메일을 확인해주세요.'),
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      }
    } on AuthFailure catch (e) {
      if (mounted) await AuthErrorDialog.show(context, e);
    } catch (_) {
      if (mounted) await AuthErrorDialog.show(context, const UnknownAuthFailure());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 찾기')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Text(
              '가입할 때 사용한 이메일을 입력하면\n비밀번호 재설정 링크를 보내드립니다.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: '이메일'),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _send,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('재설정 링크 전송'),
            ),
          ],
        ),
      ),
    );
  }
}
