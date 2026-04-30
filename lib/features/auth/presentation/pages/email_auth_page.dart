import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/usecases/sign_in_with_email_use_case.dart';
import '../../domain/usecases/sign_up_with_email_use_case.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/password.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_dialog.dart';

/// 이메일 회원가입/로그인 페이지
class EmailAuthPage extends ConsumerStatefulWidget {
  const EmailAuthPage({super.key});

  @override
  ConsumerState<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends ConsumerState<EmailAuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text; // trim 금지: 공백도 비밀번호의 일부

    if (email.isEmpty || password.isEmpty) return;

    // 이메일 형식 검증 → 오류 시 모달
    final emailFailure = Email.validate(email);
    if (emailFailure != null) {
      if (mounted) await AuthErrorDialog.show(context, emailFailure);
      return;
    }

    // 회원가입 시에만 비밀번호 형식 검증 → 오류 시 모달
    if (_isSignUp) {
      final passwordFailure = Password.validate(password);
      if (passwordFailure != null) {
        if (mounted) await AuthErrorDialog.show(context, passwordFailure);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await ref
            .read(signUpWithEmailUseCaseProvider)
            .call(SignUpWithEmailParams(email: email, password: password));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입 완료! 이메일을 확인하거나 바로 로그인해보세요.')),
          );
        }
      } else {
        await ref
            .read(signInWithEmailUseCaseProvider)
            .call(SignInWithEmailParams(email: email, password: password));
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
      appBar: AppBar(title: Text(_isSignUp ? '이메일 회원가입' : '이메일 로그인')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: '이메일'),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '비밀번호',
                helperText: _isSignUp ? '8자 이상, 특수문자 포함, 공백 없이' : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  tooltip: _isPasswordVisible ? '비밀번호 숨기기' : '비밀번호 표시',
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              obscureText: !_isPasswordVisible,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isSignUp ? '가입하기' : '로그인'),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? '이미 계정이 있나요? 로그인' : '계정이 없나요? 회원가입'),
            ),
            if (!_isSignUp)
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => context.push(AppRoutes.loginEmailForgot),
                child: const Text('비밀번호를 잊으셨나요?'),
              ),
          ],
        ),
      ),
    );
  }
}
