import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/usecases/set_push_notification_use_case.dart';
import '../providers/user_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isWithdrawing = false;

  Future<void> _withdraw() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text('정말 탈퇴할까요?\n모든 데이터가 삭제되며 복구할 수 없습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('탈퇴',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _isWithdrawing = true);
    try {
      await ref.read(withdrawUseCaseProvider).call(const NoParams());
    } on UserFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('탈퇴에 실패했습니다.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isWithdrawing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final pushEnabled = user?.pushEnabled ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 알림 설정
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SwitchListTile(
              title: const Text('푸시 알림'),
              subtitle: const Text('새 알림을 받습니다'),
              value: pushEnabled,
              activeColor: Colors.deepPurple,
              onChanged: (v) async {
                try {
                  await ref
                      .read(setPushNotificationUseCaseProvider)
                      .call(SetPushNotificationParams(enabled: v));
                } catch (_) {}
              },
            ),
          ),
          const SizedBox(height: 12),

          // 앱 정보
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const ListTile(
              leading: Icon(Icons.info_outline, color: Colors.grey),
              title: Text('앱 버전'),
              trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 24),

          // 계정 삭제
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isWithdrawing ? null : _withdraw,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isWithdrawing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.red),
                    )
                  : const Text('계정 삭제',
                      style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}
