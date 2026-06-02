import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/usecases/create_event_usecase.dart';
import '../providers/calendar_providers.dart';
import '../widgets/color_picker_row.dart';
import '../widgets/mini_calendar_picker.dart';
import '../../../friend/domain/entities/friend_entity.dart';
import '../../../friend/presentation/providers/friend_providers.dart';

// ── 알림 모드 ──────────────────────────────────────────────────────────
enum _RangeAlarmMode { none, sameDay9am, thirtyMin, oneHour, oneDay, custom }

class RangeCreatePage extends ConsumerStatefulWidget {
  const RangeCreatePage({super.key, this.prefilledDate});

  final DateTime? prefilledDate;

  @override
  ConsumerState<RangeCreatePage> createState() => _RangeCreatePageState();
}

class _RangeCreatePageState extends ConsumerState<RangeCreatePage> {
  final _titleCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledDate != null) {
      final d = widget.prefilledDate!;
      _startDate = DateTime(d.year, d.month, d.day, 0, 0);
      _endDate = DateTime(d.year, d.month, d.day, 23, 59);
    }
  }
  String _color = '#7C6AFA';
  bool _isLoading = false;

  // 알림
  _RangeAlarmMode _alarmMode = _RangeAlarmMode.sameDay9am;
  TimeOfDay _customAlarmTime = const TimeOfDay(hour: 9, minute: 0);

  // 친구 태그
  FriendEntity? _taggedFriend;

  // 장소 (값은 _locationCtrl.text에서 직접 읽음)
  final _locationCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  int? _computeNotifyBeforeMin() {
    switch (_alarmMode) {
      case _RangeAlarmMode.none:
        return null;
      case _RangeAlarmMode.thirtyMin:
        return 30;
      case _RangeAlarmMode.oneHour:
        return 60;
      case _RangeAlarmMode.oneDay:
        return 1440;
      case _RangeAlarmMode.sameDay9am:
        if (_startDate == null) return null;
        final eventMins = _startDate!.hour * 60 + _startDate!.minute;
        final diff = eventMins - 9 * 60;
        return diff > 0 ? diff : null;
      case _RangeAlarmMode.custom:
        if (_startDate == null) return null;
        final eventMins = _startDate!.hour * 60 + _startDate!.minute;
        final customMins =
            _customAlarmTime.hour * 60 + _customAlarmTime.minute;
        final diff = eventMins - customMins;
        return diff > 0 ? diff : null;
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요')),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기간을 선택해주세요')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
      // TODO: Replace with CreateRangeUseCase when backend implements
      // the separate `ranges` table (see SupabaseConstants.ranges).
      // Currently stores range as EventEntity with EventType.range.
      await ref.read(createEventUseCaseProvider).call(
            CreateEventParams(
              event: EventEntity(
                id: '',
                userId: currentUserId,
                title: _titleCtrl.text.trim(),
                location: _locationCtrl.text.trim().isEmpty
                    ? null
                    : _locationCtrl.text.trim(),
                startAt: _startDate!,
                endAt: _endDate!,
                color: _color,
                isDday: false,
                notifyBeforeMin: _computeNotifyBeforeMin(),
                status: EventStatus.pending,
                visibility: EventVisibility.public,
                createdAt: now,
                eventType: EventType.range,
              ),
            ),
          );
      ref.invalidate(calendarDataProvider);
      if (mounted) context.pop();
    } on CalendarFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('구간을 만드는 데 실패했습니다.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAlarmPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              const Text('알림 설정',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...[
                (_RangeAlarmMode.none, '없음'),
                (_RangeAlarmMode.sameDay9am, '당일 오전 9시'),
                (_RangeAlarmMode.thirtyMin, '30분 전'),
                (_RangeAlarmMode.oneHour, '1시간 전'),
                (_RangeAlarmMode.oneDay, '하루 전'),
              ].map((opt) => ListTile(
                    title: Text(opt.$2),
                    trailing: _alarmMode == opt.$1
                        ? const Icon(Icons.check, color: Color(0xFF7C6AFA))
                        : null,
                    onTap: () {
                      setState(() => _alarmMode = opt.$1);
                      Navigator.of(ctx).pop();
                    },
                  )),
              ListTile(
                title: const Text('사용자화'),
                trailing: _alarmMode == _RangeAlarmMode.custom
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_customAlarmTime.hour.toString().padLeft(2, '0')}:${_customAlarmTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: Color(0xFF7C6AFA),
                                fontWeight: FontWeight.w600),
                          ),
                          const Icon(Icons.check, color: Color(0xFF7C6AFA)),
                        ],
                      )
                    : null,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: _customAlarmTime,
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF7C6AFA))),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() {
                      _alarmMode = _RangeAlarmMode.custom;
                      _customAlarmTime = picked;
                    });
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showFriendPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FriendPickerSheet(
        onSelected: (friend) {
          setState(() => _taggedFriend = friend);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  String _alarmLabel() {
    switch (_alarmMode) {
      case _RangeAlarmMode.none:
        return '없음';
      case _RangeAlarmMode.sameDay9am:
        return '당일 오전 9시';
      case _RangeAlarmMode.thirtyMin:
        return '30분 전';
      case _RangeAlarmMode.oneHour:
        return '1시간 전';
      case _RangeAlarmMode.oneDay:
        return '하루 전';
      case _RangeAlarmMode.custom:
        return '${_customAlarmTime.hour.toString().padLeft(2, '0')}:${_customAlarmTime.minute.toString().padLeft(2, '0')} 알림';
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '날짜 선택';
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return '${dt.month}월 ${dt.day}일 (${weekdays[dt.weekday % 7]})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text('구간 추가',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장',
                    style: TextStyle(
                        color: Color(0xFF7C6AFA), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // 제목
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 18),
            decoration: const InputDecoration(
              hintText: '제목 (예: 제주도 여행 ✈)',
              hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const Divider(),
          const SizedBox(height: 16),

          // 기간 선택
          const Text('기간 선택',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: MiniCalendarPicker(
              selectedStart: _startDate,
              selectedEnd: _endDate,
              onRangeSelected: (s, e) => setState(() {
                _startDate = DateTime(s.year, s.month, s.day, 0, 0);
                _endDate = DateTime(e.year, e.month, e.day, 23, 59);
              }),
            ),
          ),
          const SizedBox(height: 16),

          // 시작/종료 칩
          Row(
            children: [
              Expanded(child: _DateChip(label: '시작', value: _fmtDate(_startDate))),
              const SizedBox(width: 8),
              Expanded(child: _DateChip(label: '종료', value: _fmtDate(_endDate))),
            ],
          ),
          const SizedBox(height: 20),

          // 컬러
          const Text('컬러 설정',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ColorPickerRow(
            selected: _color,
            onChanged: (hex) => setState(() => _color = hex),
          ),
          const SizedBox(height: 20),

          // 장소
          _RowTile(
            icon: Icons.location_on_outlined,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(
                      hintText: '장소를 입력하세요',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (_taggedFriend != null)
                  TextButton(
                    onPressed: () async {
                      final result = await context.push<String>(
                        AppRoutes.aiMidpoint,
                        extra: _taggedFriend!.friendId,
                      );
                      if (result != null && mounted) {
                        _locationCtrl.text = result;
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF7C6AFA).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFF7C6AFA),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('*AI 중간지점'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // 친구 태그
          GestureDetector(
            onTap: _showFriendPicker,
            child: _RowTile(
              icon: Icons.person_add_alt_outlined,
              trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
              child: _taggedFriend == null
                  ? const Text('친구를 태그하세요',
                      style: TextStyle(fontSize: 14, color: Colors.grey))
                  : Row(
                      children: [
                        if (_taggedFriend!.friendProfile.avatarUrl != null)
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(
                                _taggedFriend!.friendProfile.avatarUrl!),
                          )
                        else
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF7C6AFA)
                                .withValues(alpha: 0.2),
                            child: Text(
                              (_taggedFriend!.friendProfile.nickname ?? '?')[0],
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF7C6AFA),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_taggedFriend!.friendProfile.nickname ?? '',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _taggedFriend = null),
                          child: const Icon(Icons.close,
                              size: 16, color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 4),

          // 알림
          GestureDetector(
            onTap: _showAlarmPicker,
            child: _RowTile(
              icon: Icons.alarm_outlined,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _alarmLabel(),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                ],
              ),
              child: const Text('알림',
                  style: TextStyle(fontSize: 14, color: Colors.black87)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({required this.icon, required this.child, this.trailing});
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(child: child),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── 친구 선택 바텀시트 ──────────────────────────────────────────────

class _FriendPickerSheet extends ConsumerWidget {
  const _FriendPickerSheet({required this.onSelected});
  final ValueChanged<FriendEntity> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync =
        ref.watch(friendsProvider(FriendSortType.alphabetical));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text('친구 태그',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: friendsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  const Center(child: Text('친구 목록을 불러오지 못했어요')),
              data: (friends) {
                if (friends.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('아직 친구가 없어요',
                            style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  itemCount: friends.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final f = friends[i];
                    return ListTile(
                      leading: f.friendProfile.avatarUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(
                                  f.friendProfile.avatarUrl!),
                            )
                          : CircleAvatar(
                              backgroundColor: const Color(0xFF7C6AFA)
                                  .withValues(alpha: 0.2),
                              child: Text(
                                (f.friendProfile.nickname ?? '?')[0],
                                style: const TextStyle(
                                    color: Color(0xFF7C6AFA),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                      title: Text(f.friendProfile.nickname ?? ''),
                      onTap: () => onSelected(f),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
