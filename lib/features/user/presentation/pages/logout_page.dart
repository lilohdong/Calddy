import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/profile_theme.dart';

class LogoutPage extends ConsumerStatefulWidget {
  const LogoutPage({super.key});

  @override
  ConsumerState<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends ConsumerState<LogoutPage> {
  bool _isDone    = false;
  bool _isLoading = false;

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(signOutUseCaseProvider).call(const NoParams());
      if (mounted) setState(() { _isDone = true; _isLoading = false; });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('로그아웃에 실패했습니다.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      appBar: AppBar(
        backgroundColor: ProfileTheme.bg,
        elevation: 0,
        centerTitle: true,
        title: const Text('로그아웃',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: _isDone
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => context.pop(),
              ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // 아이콘
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: ProfileTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isDone
                    ? Icons.check_rounded
                    : Icons.logout_rounded,
                color: ProfileTheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isDone ? '로그아웃 되었어요' : '로그아웃 하시겠어요?',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _isDone
                  ? '이용해주셔서 감사합니다.'
                  : '다음에 다시 로그인 하면\n이전 계정으로 돌아올 수 있어요.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFFAAAAAA)),
            ),
            const Spacer(),

            // ── 하단 버튼 ────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _isDone
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRoutes.login),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: ProfileTheme.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('확인',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: ProfileTheme.primary)),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFFE0DCF5)),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                              ),
                              child: const Text('취소',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFFAAAAAA))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _logout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ProfileTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('로그아웃',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
