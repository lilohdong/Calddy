import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/usecases/set_push_notification_use_case.dart';
import '../providers/user_providers.dart';
import '../widgets/profile_theme.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  static const _kPush      = 'notif_push_enabled';
  static const _kComments  = 'notif_comments_likes';
  static const _kMentions  = 'notif_mentions';
  static const _kFriend    = 'notif_friend_schedule';
  static const _kMarketing = 'notif_marketing';

  bool _pushEnabled    = true;
  bool _commentsLikes  = true;
  bool _mentions       = true;
  bool _friendSchedule = true;
  bool _marketing      = false;

  bool _isLoading  = false;
  bool _prefsReady = false;

  bool get _allItemsOff =>
      !_commentsLikes && !_mentions && !_friendSchedule && !_marketing;

  void _onItemChanged(VoidCallback update) {
    setState(() {
      update();
      if (!_commentsLikes && !_mentions && !_friendSchedule && !_marketing) {
        _pushEnabled = false;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs    = await SharedPreferences.getInstance();
    final profile  = ref.read(currentUserProfileProvider).valueOrNull;
    final authUser = ref.read(currentUserProvider);
    final storedPush = prefs.getBool(_kPush);
    final dbPush     = profile?.pushEnabled ?? authUser?.pushEnabled ?? true;

    setState(() {
      _pushEnabled    = storedPush ?? dbPush;
      _commentsLikes  = prefs.getBool(_kComments)  ?? true;
      _mentions       = prefs.getBool(_kMentions)  ?? true;
      _friendSchedule = prefs.getBool(_kFriend)    ?? true;
      _marketing      = prefs.getBool(_kMarketing) ?? false;
      _prefsReady     = true;
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPush,      _pushEnabled);
      await prefs.setBool(_kComments,  _commentsLikes);
      await prefs.setBool(_kMentions,  _mentions);
      await prefs.setBool(_kFriend,    _friendSchedule);
      await prefs.setBool(_kMarketing, _marketing);

      await ref
          .read(setPushNotificationUseCaseProvider)
          .call(SetPushNotificationParams(enabled: _pushEnabled));
      ref.invalidate(currentUserProfileProvider);

      if (mounted) context.pop();
    } on UserFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('저장에 실패했습니다.');
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
    if (!_prefsReady) {
      return const Scaffold(
        backgroundColor: ProfileTheme.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: ProfileTheme.bg,
      appBar: AppBar(
        backgroundColor: ProfileTheme.bg,
        elevation: 0,
        centerTitle: true,
        title: const Text('알림 설정',
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: ProfileTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_rounded,
                          color: ProfileTheme.primary, size: 36),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Card(
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      title: const Text('푸시 알림',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Calddy의 알림을 받아보세요',
                          style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                      value: _pushEnabled,
                      activeColor: ProfileTheme.primary,
                      onChanged: (v) => setState(() => _pushEnabled = v),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('알림 항목',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFAAAAAA))),
                  ),
                  _Card(
                    child: Column(
                      children: [
                        _NotifItem(
                          title: '댓글 및 좋아요',
                          subtitle: '내 게시물에 반응이 오면 알려드려요',
                          value: _commentsLikes,
                          enabled: _pushEnabled,
                          onChanged: (v) => _onItemChanged(() => _commentsLikes = v),
                        ),
                        const _Divider(),
                        _NotifItem(
                          title: '멘션',
                          subtitle: '다른 사람이 나를 태그하면 알려드려요',
                          value: _mentions,
                          enabled: _pushEnabled,
                          onChanged: (v) => _onItemChanged(() => _mentions = v),
                        ),
                        const _Divider(),
                        _NotifItem(
                          title: '친구 일정 요청',
                          subtitle: '친구가 일정에 나를 초대하면 알려드려요',
                          value: _friendSchedule,
                          enabled: _pushEnabled,
                          onChanged: (v) => _onItemChanged(() => _friendSchedule = v),
                        ),
                        const _Divider(),
                        _NotifItem(
                          title: '마케팅 정보',
                          subtitle: '이벤트 및 혜택 정보를 받아보세요',
                          value: _marketing,
                          enabled: _pushEnabled,
                          onChanged: (v) => _onItemChanged(() => _marketing = v),
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
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ProfileTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('저장',
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

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: ProfileTheme.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: child,
      );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, color: ProfileTheme.divider);
}

class _NotifItem extends StatelessWidget {
  const _NotifItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: enabled ? Colors.black87 : const Color(0xFFCCCCCC))),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 12,
              color: enabled ? const Color(0xFFAAAAAA) : const Color(0xFFDDDDDD))),
      value: enabled ? value : false,
      activeColor: ProfileTheme.primary,
      onChanged: enabled ? onChanged : null,
    );
  }
}
