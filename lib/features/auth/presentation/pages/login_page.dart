import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/sign_in_with_email_use_case.dart';
import '../../domain/value_objects/email.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_dialog.dart';
import '../widgets/auth_ui_widgets.dart';

/// 로그인 화면
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _emailError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onEmailChanged(String v) {
    final err =
        v.isEmpty ? null : (Email.validate(v) != null ? '올바르지 않은 이메일 형식입니다.' : null);
    if (_emailError != err) setState(() => _emailError = err);
  }

  Future<void> _signInWithEmail() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) return;
    if (_emailError != null) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(signInWithEmailUseCaseProvider)
          .call(SignInWithEmailParams(email: email, password: password));
    } on AuthFailure catch (e) {
      if (mounted) await AuthErrorDialog.show(context, e);
    } catch (_) {
      if (mounted) await AuthErrorDialog.show(context, const UnknownAuthFailure());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(signInWithGoogleUseCaseProvider).call(const NoParams());
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
      backgroundColor: kAuthBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 52),

              // 로고
              const AuthLogoBox(size: 72),
              const SizedBox(height: 20),

              // 제목
              const Text(
                '환영해요 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 36),

              // 이메일 입력
              AuthTextField(
                controller: _emailCtrl,
                hint: '이메일 (Email)',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                onChanged: _onEmailChanged,
                errorText: _emailError,
              ),
              const SizedBox(height: 12),

              // 비밀번호 입력
              AuthTextField(
                controller: _passwordCtrl,
                hint: '비밀번호',
                prefixIcon: Icons.lock_outline,
                obscureText: !_passwordVisible,
                enabled: !_isLoading,
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
              const SizedBox(height: 20),

              // 로그인 버튼
              AuthPurpleButton(
                label: '로그인',
                isLoading: _isLoading,
                onPressed: _signInWithEmail,
              ),
              const SizedBox(height: 20),

              // 또는 구분선
              const AuthOrDivider(),
              const SizedBox(height: 20),

              // Google 로그인
              AuthGoogleButton(
                isLoading: _isLoading,
                onPressed: _signInWithGoogle,
              ),
              const SizedBox(height: 36),

              // 하단 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '처음이신가요? ',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => context.push(AppRoutes.loginEmail),
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        color: kAuthPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.grey.shade300,
                  ),
                  GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () => context.push(AppRoutes.loginEmailForgot),
                    child: Text(
                      '비밀번호 찾기',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
