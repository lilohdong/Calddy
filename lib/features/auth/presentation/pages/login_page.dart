import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/usecase/usecase.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_error_dialog.dart';

/// 로그인 화면
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoading = false;

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month_rounded, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 16),
            const Text(
              'Calddy',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('친구와 함께하는 캘린더 관리'),
            const SizedBox(height: 64),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithGoogle,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: const Text('Google 계정으로 시작하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(250, 50),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => context.push(AppRoutes.loginEmail),
              child: const Text('이메일로 시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}
