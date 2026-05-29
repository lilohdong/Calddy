import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 프로필 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // 아바타
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.deepPurple.shade100,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          (user?.nickname?.isNotEmpty == true)
                              ? user!.nickname![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.nickname ?? '닉네임 없음',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.editProfile),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(160, 40),
                    side: const BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('프로필 편집',
                      style: TextStyle(color: Colors.deepPurple)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 메뉴 카드
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: '알림',
                  onTap: () => context.push(AppRoutes.notifications),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: '설정',
                  onTap: () => context.push(AppRoutes.settings),
                ),
                const Divider(height: 1),
                _MenuItem(
                  icon: Icons.logout,
                  label: '로그아웃',
                  labelColor: Colors.red,
                  onTap: () async {
                    await ref
                        .read(signOutUseCaseProvider)
                        .call(const NoParams());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: labelColor ?? Colors.grey.shade700),
      title: Text(label,
          style: TextStyle(color: labelColor, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
