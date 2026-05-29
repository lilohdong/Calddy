import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/usecases/sign_up_with_email_use_case.dart';
import '../../domain/value_objects/email.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_dialog.dart';
import '../widgets/auth_ui_widgets.dart';

/// 이메일 회원가입 페이지
class EmailAuthPage extends ConsumerStatefulWidget {
  const EmailAuthPage({super.key});

  @override
  ConsumerState<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends ConsumerState<EmailAuthPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  // 이메일 오류
  String? _emailError;

  // 비밀번호 실시간 검증 상태
  bool _noSpace = false;
  bool _minLength = false;
  bool _hasSpecial = false;

  // 비밀번호 확인 일치 여부
  bool get _confirmMatch =>
      _confirmCtrl.text.isNotEmpty &&
      _confirmCtrl.text == _passwordCtrl.text;

  // 가입 완료 버튼 활성화 조건
  bool get _canSubmit =>
      _emailCtrl.text.trim().isNotEmpty &&
      _emailError == null &&
      _noSpace &&
      _minLength &&
      _hasSpecial &&
      _confirmMatch;

  static final _specialChar =
      RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _onEmailChanged(String v) {
    final err =
        v.isEmpty ? null : (Email.validate(v) != null ? '올바르지 않은 이메일 형식입니다.' : null);
    if (_emailError != err) setState(() => _emailError = err);
  }

  void _onPasswordChanged(String v) {
    setState(() {
      _noSpace = !v.contains(RegExp(r'\s'));
      _minLength = v.length >= 8;
      _hasSpecial = _specialChar.hasMatch(v);
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(signUpWithEmailUseCaseProvider)
          .call(SignUpWithEmailParams(email: email, password: password));
      if (mounted) {
        context.push(AppRoutes.loginEmailVerify, extra: email);
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
      backgroundColor: kAuthBg,
      appBar: AppBar(
        backgroundColor: kAuthBg,
        elevation: 0,
        title: const Text(
          '회원가입',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 헤딩
              const Text(
                '새로운 시작을 함께 해요',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Calddy와 일정을 공유할 준비가 되셨나요?',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 32),

              // 이메일
              const _FieldLabel(label: '이메일'),
              const SizedBox(height: 6),
              AuthTextField(
                controller: _emailCtrl,
                hint: 'example@mail.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                onChanged: _onEmailChanged,
                errorText: _emailError,
              ),
              const SizedBox(height: 20),

              // 비밀번호
              const _FieldLabel(label: '비밀번호'),
              const SizedBox(height: 6),
              AuthTextField(
                controller: _passwordCtrl,
                hint: '공백 불가, 8자 이상, 특수문자 포함',
                prefixIcon: Icons.key_outlined,
                obscureText: !_passwordVisible,
                enabled: !_isLoading,
                onChanged: _onPasswordChanged,
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
              const SizedBox(height: 8),

              // 비밀번호 검증 힌트
              _ValidationHints(
                noSpace: _noSpace,
                minLength: _minLength,
                hasSpecial: _hasSpecial,
                hasInput: _passwordCtrl.text.isNotEmpty,
              ),
              const SizedBox(height: 20),

              // 비밀번호 확인
              const _FieldLabel(label: '비밀번호 확인'),
              const SizedBox(height: 6),
              AuthTextField(
                controller: _confirmCtrl,
                hint: '비밀번호를 다시 입력하세요',
                prefixIcon: Icons.key_outlined,
                obscureText: !_confirmVisible,
                enabled: !_isLoading,
                onChanged: (_) => setState(() {}),
                suffixIcon: _confirmCtrl.text.isNotEmpty
                    ? Icon(
                        _confirmMatch
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        color: _confirmMatch
                            ? Colors.green.shade400
                            : Colors.red.shade300,
                        size: 20,
                      )
                    : IconButton(
                        icon: Icon(
                          _confirmVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _confirmVisible = !_confirmVisible),
                      ),
              ),
              const SizedBox(height: 40),

              // 가입 완료 버튼
              AuthPurpleButton(
                label: '이메일 인증',
                isLoading: _isLoading,
                enabled: _canSubmit,
                onPressed: _submit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 필드 레이블 ────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
    );
  }
}

// ── 비밀번호 검증 힌트 ─────────────────────────────────────────────────────────

class _ValidationHints extends StatelessWidget {
  const _ValidationHints({
    required this.noSpace,
    required this.minLength,
    required this.hasSpecial,
    required this.hasInput,
  });

  final bool noSpace;
  final bool minLength;
  final bool hasSpecial;
  final bool hasInput;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Hint(label: '공백 없음', passed: noSpace, hasInput: hasInput),
        const SizedBox(width: 12),
        _Hint(label: '8자 이상', passed: minLength, hasInput: hasInput),
        const SizedBox(width: 12),
        _Hint(label: '특수문자 포함', passed: hasSpecial, hasInput: hasInput),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({
    required this.label,
    required this.passed,
    required this.hasInput,
  });

  final String label;
  final bool passed;
  final bool hasInput;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;

    if (!hasInput) {
      color = Colors.grey.shade400;
      icon = Icons.circle_outlined;
    } else if (passed) {
      color = Colors.green.shade500;
      icon = Icons.check_circle_rounded;
    } else {
      color = Colors.red.shade400;
      icon = Icons.cancel_rounded;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
