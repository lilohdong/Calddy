import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/usecases/send_otp_use_case.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_ui_widgets.dart';

/// 회원가입 후 이메일 인증 안내 페이지
class EmailVerifyPage extends ConsumerStatefulWidget {
  const EmailVerifyPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<EmailVerifyPage> createState() => _EmailVerifyPageState();
}

class _EmailVerifyPageState extends ConsumerState<EmailVerifyPage> {
  bool _isResending = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // extra 없이 라우트에 진입한 경우 — 로그인으로 즉시 리다이렉트
    if (widget.email.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.login);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      // dispose 직후 콜백이 실행될 수 있으므로 먼저 취소 후 mounted 확인
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _isResending) return;

    setState(() => _isResending = true);
    try {
      await ref
          .read(sendOtpUseCaseProvider)
          .call(SendOtpParams(email: widget.email));
      if (mounted) {
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('인증 메일을 다시 보냈어요.'),
            backgroundColor: kAuthPurple,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on AuthFailure {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('메일 전송에 실패했어요. 잠시 후 다시 시도해주세요.'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAuthBg,
      appBar: AppBar(
        backgroundColor: kAuthBg,
        elevation: 0,
        title: const Text(
          '이메일 인증',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // 아이콘 서클
              const AuthIconCircle(
                icon: Icons.mark_email_unread_outlined,
                size: 88,
                iconSize: 42,
              ),
              const SizedBox(height: 28),

              // 제목
              const Text(
                '이메일을 확인해주세요',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // 이메일 강조 안내
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey.shade600, height: 1.6),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kAuthPurple,
                      ),
                    ),
                    const TextSpan(text: ' 으로\n인증 링크를 보냈어요.'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 안내 박스
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kAuthPurpleLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: kAuthPurple, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '받은 편지함에서 인증 링크를 클릭하면 가입이 완료돼요.\n'
                        '메일이 보이지 않으면 스팸함도 확인해보세요.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // 로그인 화면으로
              AuthPurpleButton(
                label: '로그인 화면으로',
                isLoading: false,
                onPressed: () => context.go(AppRoutes.login),
              ),
              const SizedBox(height: 16),

              // 재전송 버튼
              TextButton(
                onPressed: (_cooldown > 0 || _isResending) ? null : _resend,
                child: _isResending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kAuthPurple),
                      )
                    : Text(
                        _cooldown > 0
                            ? '재전송 (${_cooldown}초 후 가능)'
                            : '인증 메일 다시 보내기',
                        style: TextStyle(
                          fontSize: 14,
                          color: _cooldown > 0
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
