import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 이메일 인증 실행
  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await ref.read(signUpWithEmailUseCaseProvider)(email: email, password: password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원가입 성공! 메일함을 확인하거나 바로 로그인해보세요.')),
          );
        }
      } else {
        await ref.read(signInWithEmailUseCaseProvider)(email: email, password: password);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
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
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: _isLoading 
                ? const CircularProgressIndicator() 
                : Text(_isSignUp ? '가입하기' : '로그인'),
            ),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? '이미 계정이 있나요? 로그인' : '계정이 없나요? 회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
