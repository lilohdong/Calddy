import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/profile_theme.dart';

class EmailSettingPage extends ConsumerStatefulWidget {
  const EmailSettingPage({super.key});

  @override
  ConsumerState<EmailSettingPage> createState() => _EmailSettingPageState();
}

class _EmailSettingPageState extends ConsumerState<EmailSettingPage> {
  late final TextEditingController _emailCtrl;
  late String _initialEmail;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  bool get _isFormatOk  => _emailRegex.hasMatch(_emailCtrl.text.trim());
  bool get _hasAtSign   => _emailCtrl.text.contains('@');
  bool get _isChanged   => _emailCtrl.text.trim() != _initialEmail;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _initialEmail = user?.email ?? '';
    _emailCtrl    = TextEditingController(text: _initialEmail);
    _emailCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_isFormatOk) {
      _showError('올바른 이메일 형식을 입력해주세요.');
      return;
    }
    if (!_isChanged) {
      context.pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('이메일 변경은 백엔드 연동 후 사용 가능합니다. (백엔드팀 문의)'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email    = _emailCtrl.text.trim();
    final hasTyped = email.isNotEmpty;

    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      appBar: AppBar(
        backgroundColor: ProfileTheme.bg,
        elevation: 0,
        centerTitle: true,
        title: const Text('이메일 변경',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 24),
                children: [
                  // ── 이메일 입력 카드 ──────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: ProfileTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 8,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('이메일',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFAAAAAA),
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE8E4F8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE8E4F8)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: ProfileTheme.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            suffixIcon: email.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    color: Colors.grey,
                                    onPressed: () => _emailCtrl.clear(),
                                  )
                                : null,
                          ),
                        ),

                        // 유효성 메시지
                        if (hasTyped) ...[
                          const SizedBox(height: 10),
                          _ValidationRow(
                            ok: _hasAtSign,
                            text: '@ 기호가 포함되어야 해요.',
                          ),
                          const SizedBox(height: 4),
                          _ValidationRow(
                            ok: _isFormatOk,
                            text: '올바른 이메일 형식이에요.',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 저장 버튼 ─────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProfileTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('저장',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationRow extends StatelessWidget {
  const _ValidationRow({required this.ok, required this.text});
  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(ok ? Icons.check : Icons.close,
            size: 14,
            color: ok ? Colors.green : Colors.redAccent),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 12,
                color: ok ? Colors.green : Colors.redAccent)),
      ],
    );
  }
}
