import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/user_providers.dart';
import '../widgets/profile_theme.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser   = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profile    = profileAsync.valueOrNull;

    final nickname  = profile?.nickname   ?? authUser?.nickname  ?? '';
    final avatarUrl = profile?.avatarUrl  ?? authUser?.avatarUrl;
    final birthDate = profile?.birthDate  ?? authUser?.birthDate;
    final pushOn    = profile?.pushEnabled ?? authUser?.pushEnabled ?? false;
    final email     = authUser?.email ?? '';

    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      appBar: AppBar(
        backgroundColor: ProfileTheme.bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '프로필',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: ProfileTheme.primaryLight,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            nickname.isNotEmpty
                                ? nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: ProfileTheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nickname.isNotEmpty ? nickname : '닉네임 없음',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _MenuCard(
              children: [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: '프로필',
                  value: nickname,
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
                _MenuItem(
                  icon: Icons.mail_outline_rounded,
                  label: '이메일',
                  value: email,
                  onTap: () => context.push(AppRoutes.emailSetting),
                ),
                _MenuItem(
                  icon: Icons.cake_outlined,
                  label: '생년월일',
                  value: birthDate != null
                      ? '${birthDate.year}. '
                          '${birthDate.month.toString().padLeft(2, '0')}. '
                          '${birthDate.day.toString().padLeft(2, '0')}'
                      : '미설정',
                  onTap: () => context.push(AppRoutes.birthDateSetting),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: '알림 설정',
                  value: pushOn ? 'ON' : 'OFF',
                  onTap: () => context.push(AppRoutes.notificationSettings),
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ActionButton(
              label: '로그아웃',
              backgroundColor: ProfileTheme.primary,
              textColor: Colors.white,
              onTap: () => context.push(AppRoutes.logout),
            ),
            const SizedBox(height: 10),
            _ActionButton(
              label: '회원 탈퇴',
              backgroundColor: ProfileTheme.dangerLight,
              textColor: ProfileTheme.danger,
              onTap: () => context.push(AppRoutes.withdraw),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ProfileTheme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: ProfileTheme.primary, size: 22),
          title: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13)),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFCCCCCC), size: 20),
              ],
            ],
          ),
          onTap: onTap,
        ),
        if (!isLast)
          const Divider(height: 1, indent: 52, color: ProfileTheme.divider),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
        ),
      ),
    );
  }
}
