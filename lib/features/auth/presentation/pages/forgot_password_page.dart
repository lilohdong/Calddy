import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/usecases/send_password_reset_email_use_case.dart';
import '../../domain/value_objects/email.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_dialog.dart';
import '../widgets/auth_ui_widgets.dart';

/// 비밀번호 찾기 페이지
/// - 초기 상태: 이메일 입력 → "인증 메일 보내기"
/// - 전송 완료 상태: 성공 화면 → "로그인 화면으로" or "메일 다시 보내기"
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String _sentEmail = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    final emailFailure = Email.validate(email);
    if (emailFailure != null) {
      if (mounted) await AuthErrorDialog.show(context, emailFailure);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(sendPasswordResetEmailUseCaseProvider)
          .call(SendPasswordResetEmailParams(email));

      // Supabase는 이메일 존재 여부와 무관하게 성공 반환 (유저 열거 방지)
      if (mounted) {
        setState(() {
          _sent = true;
          _sentEmail = email;
        });
      }
    } on AuthFailure catch (e) {
      if (mounted) await AuthErrorDialog.show(context, e);
    } catch (_) {
      if (mounted) await AuthErrorDialog.show(context, const UnknownAuthFailure());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resend() {
    setState(() {
      _sent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAuthBg,
      appBar: AppBar(
        backgroundColor: kAuthBg,
        elevation: 0,
        title: const Text(
          '비밀번호 찾기',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _sent
            ? _SentView(
                email: _sentEmail,
                onGoLogin: () => context.go(AppRoutes.login),
                onResend: _resend,
              )
            : _InputView(
                controller: _emailCtrl,
                isLoading: _isLoading,
                onSend: _send,
              ),
      ),
    );
  }
}

// ── 이메일 입력 화면 ──────────────────────────────────────────────────────────

class _InputView extends StatelessWidget {
  const _InputView({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // 아이콘 서클
          const AuthIconCircle(
            icon: Icons.email_outlined,
            size: 88,
            iconSize: 40,
          ),
          const SizedBox(height: 28),

          // 제목
          const Text(
            '가입하신 이메일을 알려주세요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '비밀번호 재설정 링크를\n해당 이메일로 보내드릴게요.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 이메일 입력
          AuthTextField(
            controller: controller,
            hint: 'example@mail.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
          ),
          const SizedBox(height: 24),

          // 전송 버튼
          AuthPurpleButton(
            label: '인증 메일 보내기',
            isLoading: isLoading,
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

// ── 전송 완료 화면 ────────────────────────────────────────────────────────────

class _SentView extends StatelessWidget {
  const _SentView({
    required this.email,
    required this.onGoLogin,
    required this.onResend,
  });

  final String email;
  final VoidCallback onGoLogin;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // 체크 아이콘 서클
          const AuthIconCircle(
            icon: Icons.check_rounded,
            size: 88,
            iconSize: 44,
          ),
          const SizedBox(height: 28),

          // 제목
          const Text(
            '메일이 전송되었어요',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              children: [
                TextSpan(
                  text: email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: kAuthPurple,
                  ),
                ),
                const TextSpan(text: ' 으로\n보내드린 링크를 확인해주세요.'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 안내 문구
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kAuthPurpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: kAuthPurple, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '메일이 보이지 않나요? 스팸함을 확인해보세요. '
                    '링크는 30분간 유효해요.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 로그인 화면으로
          AuthPurpleButton(
            label: '로그인 화면으로',
            isLoading: false,
            onPressed: onGoLogin,
          ),
          const SizedBox(height: 16),

          // 메일 다시 보내기
          TextButton(
            onPressed: onResend,
            child: Text(
              '메일 다시 보내기',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
