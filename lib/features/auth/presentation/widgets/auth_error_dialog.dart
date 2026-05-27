import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/failures.dart';

/// Auth 오류 발생 시 표시하는 모달 다이얼로그
class AuthErrorDialog extends StatelessWidget {
  final AuthFailure failure;

  const AuthErrorDialog({super.key, required this.failure});

  /// [failure]를 분석하여 적절한 타이틀과 아이콘을 반환
  _DialogContent _buildContent() {
    return switch (failure) {
      InvalidCredentialsFailure() => const _DialogContent(
          icon: Icons.lock_outline,
          title: '로그인 실패',
        ),
      EmailAlreadyInUseFailure() => const _DialogContent(
          icon: Icons.email_outlined,
          title: '이메일 중복',
        ),
      EmailNotConfirmedFailure() => const _DialogContent(
          icon: Icons.mark_email_unread_outlined,
          title: '이메일 인증 필요',
        ),
      GoogleSignInCancelledFailure() => const _DialogContent(
          icon: Icons.cancel_outlined,
          title: '로그인 취소',
        ),
      GoogleConfigMissingFailure() => const _DialogContent(
          icon: Icons.settings_outlined,
          title: '구글 로그인 설정 오류',
        ),
      TooManyRequestsFailure() => const _DialogContent(
          icon: Icons.hourglass_empty_outlined,
          title: '요청 초과',
        ),
      DuplicateNicknameFailure() => const _DialogContent(
          icon: Icons.person_outline,
          title: '닉네임 중복',
        ),
      NetworkFailure() => const _DialogContent(
          icon: Icons.wifi_off_outlined,
          title: '네트워크 오류',
        ),
      PasswordValidationFailure() => const _DialogContent(
          icon: Icons.password_outlined,
          title: '비밀번호 형식 오류',
        ),
      EmailValidationFailure() => const _DialogContent(
          icon: Icons.alternate_email,
          title: '이메일 형식 오류',
        ),
      NicknameValidationFailure() => const _DialogContent(
          icon: Icons.badge_outlined,
          title: '닉네임 형식 오류',
        ),
      InvalidOtpFailure() => const _DialogContent(
          icon: Icons.sms_failed_outlined,
          title: '인증번호 오류',
        ),
      OtpExpiredFailure() => const _DialogContent(
          icon: Icons.timer_off_outlined,
          title: '인증번호 만료',
        ),
      WeakPasswordFailure() => const _DialogContent(
          icon: Icons.lock_reset_outlined,
          title: '비밀번호 강도 미달',
        ),
      SamePasswordFailure() => const _DialogContent(
          icon: Icons.password_outlined,
          title: '비밀번호 변경 불가',
        ),
      SessionExpiredAuthFailure() => const _DialogContent(
          icon: Icons.login_outlined,
          title: '세션 만료',
        ),
      UnknownAuthFailure() => const _DialogContent(
          icon: Icons.error_outline,
          title: '오류 발생',
        ),
    };
  }

  /// 다이얼로그를 표시하는 정적 헬퍼.
  /// [GoogleSignInCancelledFailure]는 사용자가 직접 취소한 것이므로 표시하지 않음.
  static Future<void> show(BuildContext context, AuthFailure failure) {
    if (failure is GoogleSignInCancelledFailure) return Future.value();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AuthErrorDialog(failure: failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(content.icon, size: 40, color: colorScheme.error),
      title: Text(
        content.title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      content: Text(
        failure.message,
        textAlign: TextAlign.center,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('확인'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _DialogContent {
  final IconData icon;
  final String title;

  const _DialogContent({required this.icon, required this.title});
}
