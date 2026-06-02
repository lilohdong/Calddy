import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../providers/user_providers.dart';
import '../widgets/profile_theme.dart';

class WithdrawPage extends ConsumerStatefulWidget {
  const WithdrawPage({super.key});

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  int _step = 1;
  final _passwordCtrl = TextEditingController();
  bool _obscure   = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _withdraw() async {
    if (_passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 입력해주세요.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(withdrawUseCaseProvider).call(const NoParams());
      // 세션 소멸 → GoRouter가 /login으로 자동 리다이렉트
    } on WithdrawFailure catch (e) {
      _showError(e.message);
    } on UserFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('탈퇴에 실패했습니다. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      appBar: AppBar(
        backgroundColor: ProfileTheme.bg,
        elevation: 0,
        centerTitle: true,
        title: const Text('회원 탈퇴',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (_step == 2) setState(() => _step = 1);
            else context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: _step == 1
            ? _StepOne(onNext: () => setState(() => _step = 2))
            : _StepTwo(
                passwordCtrl: _passwordCtrl,
                obscure: _obscure,
                isLoading: _isLoading,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onWithdraw: _withdraw,
              ),
      ),
    );
  }
}

// ── Step 1: 경고 화면 ──────────────────────────────────────────────

class _StepOne extends StatelessWidget {
  const _StepOne({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: ProfileTheme.dangerLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded,
                      color: ProfileTheme.danger, size: 44),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text('정말 탈퇴하시겠어요?',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '탈퇴 후에는 복구가 불가하며,\n모든 데이터가 삭제됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Color(0xFFAAAAAA)),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ProfileTheme.dangerLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    _Bullet('내 정보 및 프로필이 삭제돼요.'),
                    SizedBox(height: 8),
                    _Bullet('작성한 게시글, 댓글이 삭제돼요.'),
                    SizedBox(height: 8),
                    _Bullet('보유한 데이터가 모두 삭제돼요.'),
                    SizedBox(height: 8),
                    _Bullet('동일한 이메일로 30일간 재가입할 수 없어요.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE0DCF5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('취소',
                        style: TextStyle(
                            fontSize: 16, color: Color(0xFFAAAAAA))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProfileTheme.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('다음',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('· ',
            style: TextStyle(
                color: ProfileTheme.danger, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13, color: ProfileTheme.danger)),
        ),
      ],
    );
  }
}

// ── Step 2: 비밀번호 확인 화면 ─────────────────────────────────────

class _StepTwo extends StatelessWidget {
  const _StepTwo({
    required this.passwordCtrl,
    required this.obscure,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onWithdraw,
  });

  final TextEditingController passwordCtrl;
  final bool obscure;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            children: [
              const Text('비밀번호를 한 번 더 입력해주세요',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('본인 확인을 위해 비밀번호가 필요해요.',
                  style: TextStyle(
                      fontSize: 14, color: Color(0xFFAAAAAA))),
              const SizedBox(height: 24),
              const Text('비밀번호',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: ProfileTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Color(0xFFCCCCCC)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFFCCCCCC),
                      ),
                      onPressed: onToggleObscure,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: ProfileTheme.card,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFE09000), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '탈퇴하기를 누르시면 즉시 계정과 모든 데이터가 삭제되며, 복구할 수 없습니다.',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFFB07000)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfileTheme.danger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('탈퇴하기',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }
}
