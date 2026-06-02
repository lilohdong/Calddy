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
import '../../domain/usecases/create_habit_usecase.dart';
import '../../../friend/domain/entities/friend_entity.dart';
import '../../../friend/presentation/providers/friend_providers.dart';
import '../../../appointment/domain/usecases/create_appointment_use_case.dart';
import '../../../appointment/presentation/providers/appointment_providers.dart';

// ── 프리필 데이터 (합쳐보기에서 전달) ─────────────────────────────────────────
class EventCreateExtra {
  final DateTime? prefilledDate;
  final List<String> inviteeIds;
  final List<String> inviteeNicknames;

  const EventCreateExtra({
    this.prefilledDate,
    this.inviteeIds = const [],
    this.inviteeNicknames = const [],
  });
}

// ── 알림 모드 ──────────────────────────────────────────────────────────
enum _AlarmMode { none, thirtyMin, oneHour, oneDay, sameDay9am, custom }

class EventCreatePage extends ConsumerStatefulWidget {
  const EventCreatePage({super.key, this.extra});

  final EventCreateExtra? extra;

  @override
  ConsumerState<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends ConsumerState<EventCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  late DateTime _startAt;
  late DateTime _endAt;

  String _color = '#7C6AFA';
  bool _isLoading = false;
  bool _isDday = false;

  // 알림
  _AlarmMode _alarmMode = _AlarmMode.sameDay9am;
  TimeOfDay _customAlarmTime = const TimeOfDay(hour: 9, minute: 0);

  // 반복
  RecurrenceType? _recurrenceType;
  int? _recurrenceWeekday;
  int? _recurrenceMonthDay;

  // 친구 태그 — 합쳐보기 프리필 (다중) + 개별 선택 (단일)
  List<String> _prefilledIds = [];
  List<String> _prefilledNames = [];
  FriendEntity? _taggedFriend; // 개별 선택 친구 (AI 중간지점용)

  /// 약속 초대 대상 IDs (프리필 + 개별 선택 합산, 중복 제거)
  List<String> get _allInviteeIds {
    final all = {..._prefilledIds};
    if (_taggedFriend != null) all.add(_taggedFriend!.friendId);
    return all.toList();
  }

  /// 합쳐보기에서 왔는지 여부
  bool get _isFromMerge => _prefilledIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final extra = widget.extra;
    final base = extra?.prefilledDate ?? DateTime.now();
    _startAt = DateTime(base.year, base.month, base.day, 9, 0);
    _endAt = DateTime(base.year, base.month, base.day, 23, 59);

    if (extra != null) {
      _prefilledIds = List.from(extra.inviteeIds);
      _prefilledNames = List.from(extra.inviteeNicknames);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  int? _computeNotifyBeforeMin() {
    switch (_alarmMode) {
      case _AlarmMode.none:
        return null;
      case _AlarmMode.thirtyMin:
        return 30;
      case _AlarmMode.oneHour:
        return 60;
      case _AlarmMode.oneDay:
        return 1440;
      case _AlarmMode.sameDay9am:
        final eventMins = _startAt.hour * 60 + _startAt.minute;
        final diff = eventMins - 9 * 60;
        return diff > 0 ? diff : null;
      case _AlarmMode.custom:
        final eventMins = _startAt.hour * 60 + _startAt.minute;
        final customMins =
            _customAlarmTime.hour * 60 + _customAlarmTime.minute;
        final diff = eventMins - customMins;
        return diff > 0 ? diff : null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final currentUserId =
          Supabase.instance.client.auth.currentUser?.id ?? '';
      final now = DateTime.now();

      List<int>? recurrenceDays;
      if (_recurrenceType == RecurrenceType.weekly) {
        recurrenceDays = [_recurrenceWeekday ?? _startAt.weekday];
      } else if (_recurrenceType == RecurrenceType.monthly) {
        recurrenceDays = [_recurrenceMonthDay ?? _startAt.day];
      }

      final baseEntity = EventEntity(
        id: '',
        userId: currentUserId,
        title: _titleCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        startAt: _startAt,
        endAt: _endAt,
        color: _color,
        isDday: _isDday,
        memo: _memoCtrl.text.trim().isEmpty
            ? null
            : _memoCtrl.text.trim(),
        notifyBeforeMin: _computeNotifyBeforeMin(),
        status: EventStatus.pending,
        visibility: EventVisibility.public,
        createdAt: now,
        recurrenceType: _recurrenceType,
        recurrenceDays: recurrenceDays,
      );

      // 1. 이벤트 생성
      EventEntity? createdEvent;
      if (_recurrenceType != null) {
        // 반복 이벤트: 여러 인스턴스 일괄 생성
        await ref.read(createHabitUseCaseProvider).call(
              CreateHabitParams(template: baseEntity),
            );
      } else {
        // 단일 이벤트: 기존 방식
        createdEvent = await ref.read(createEventUseCaseProvider).call(
              CreateEventParams(event: baseEntity),
            );
      }

      // 2. 초대할 친구가 있으면 약속(Appointment) 자동 생성 (단일 이벤트만)
      final inviteeIds = _allInviteeIds;
      if (inviteeIds.isNotEmpty && createdEvent != null) {
        await ref.read(createAppointmentUseCaseProvider).call(
              CreateAppointmentParams(
                eventId: createdEvent.id,
                inviteeIds: inviteeIds,
              ),
            );
      }

      ref.invalidate(calendarDataProvider);

      if (mounted) {
        // createdEvent == null이면 반복 이벤트 → 약속 미생성이므로 스낵바 표시 안 함
        if (inviteeIds.isNotEmpty && createdEvent != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text('일정 생성 & 초대장을 보냈어요! 🎉'),
                ],
              ),
              backgroundColor: const Color(0xFF7C6AFA),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        context.pop();
      }
    } on CalendarFailure catch (e) {
      _showError(e.message);
    } on AppointmentFailure catch (e) {
      // 이벤트는 생성됐으므로 캘린더 갱신 + 페이지 닫기는 수행
      ref.invalidate(calendarDataProvider);
      if (mounted) {
        context.pop();
        _showError('일정은 만들었지만 초대 전송에 실패했어요: ${e.message}');
      }
    } catch (_) {
      _showError('일정을 만드는 데 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
                (_AlarmMode.none, '없음'),
                (_AlarmMode.sameDay9am, '당일 오전 9시'),
                (_AlarmMode.thirtyMin, '30분 전'),
                (_AlarmMode.oneHour, '1시간 전'),
                (_AlarmMode.oneDay, '하루 전'),
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
                trailing: _alarmMode == _AlarmMode.custom
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
                      _alarmMode = _AlarmMode.custom;
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

  void _showRepeatPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _RepeatPickerSheet(
        initialType: _recurrenceType,
        initialWeekday: _recurrenceWeekday,
        initialMonthDay: _recurrenceMonthDay,
        startDate: _startAt,
        onChanged: (type, weekday, monthDay) {
          setState(() {
            _recurrenceType = type;
            _recurrenceWeekday = weekday;
            _recurrenceMonthDay = monthDay;
          });
        },
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
        excludeIds: _prefilledIds,
        onSelected: (friend) {
          setState(() => _taggedFriend = friend);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  String _alarmLabel() {
    switch (_alarmMode) {
      case _AlarmMode.none:
        return '없음';
      case _AlarmMode.sameDay9am:
        return '당일 오전 9시';
      case _AlarmMode.thirtyMin:
        return '30분 전';
      case _AlarmMode.oneHour:
        return '1시간 전';
      case _AlarmMode.oneDay:
        return '하루 전';
      case _AlarmMode.custom:
        return '${_customAlarmTime.hour.toString().padLeft(2, '0')}:${_customAlarmTime.minute.toString().padLeft(2, '0')} 알림';
    }
  }

  String _repeatLabel() {
    if (_recurrenceType == null) return '없음';
    if (_recurrenceType == RecurrenceType.daily) return '매일';
    if (_recurrenceType == RecurrenceType.weekly) {
      const names = [
        '',
        '매주 월요일',
        '매주 화요일',
        '매주 수요일',
        '매주 목요일',
        '매주 금요일',
        '매주 토요일',
        '매주 일요일'
      ];
      return names[_recurrenceWeekday ?? _startAt.weekday];
    }
    if (_recurrenceType == RecurrenceType.monthly) {
      return '매월 ${_recurrenceMonthDay ?? _startAt.day}일';
    }
    return '없음';
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
        title: Text(
          _isFromMerge ? '공동 일정 추가' : '일정 추가',
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    _isFromMerge ? '저장 & 초대' : '저장',
                    style: const TextStyle(
                        color: Color(0xFF7C6AFA),
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // 합쳐보기에서 왔을 때: 배너
            if (_isFromMerge) ...[
              _MergeBanner(names: _prefilledNames),
              const SizedBox(height: 12),
            ],

            // 제목
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요',
                hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
            ),
            const Divider(),
            const SizedBox(height: 12),

            // 컬러
            const _Label('컬러 설정'),
            const SizedBox(height: 10),
            ColorPickerRow(
              selected: _color,
              onChanged: (hex) => setState(() => _color = hex),
            ),
            const SizedBox(height: 16),

            // 시작/종료 날짜
            _SettingCard(
              icon: Icons.calendar_today_outlined,
              child: Column(
                children: [
                  _DateRow(
                    label: '시작',
                    value: _startAt,
                    onChanged: (dt) => setState(() {
                      _startAt = dt;
                      if (_endAt.isBefore(_startAt)) {
                        _endAt = _startAt;
                      }
                    }),
                  ),
                  const Divider(height: 16),
                  _DateRow(
                    label: '종료',
                    value: _endAt,
                    onChanged: (dt) => setState(() => _endAt = dt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 장소
            _SettingCard(
              icon: Icons.location_on_outlined,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(
                        hintText: '장소 설정',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  // AI 중간지점 버튼
                  // - 합쳐보기 모드: 프리필 친구 IDs 전달
                  // - 일반 모드: 단일 태그 친구 있을 때만
                  if (_isFromMerge || _taggedFriend != null)
                    TextButton(
                      onPressed: () async {
                        final extra = _isFromMerge
                            ? _prefilledIds          // List<String>
                            : _taggedFriend!.friendId; // String
                        final result = await context.push<String>(
                          AppRoutes.aiMidpoint,
                          extra: extra,
                        );
                        if (result != null && mounted) {
                          setState(() => _locationCtrl.text = result);
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF7C6AFA).withValues(alpha: 0.1),
                        foregroundColor: const Color(0xFF7C6AFA),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('*AI 중간지점'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 친구 태그
            _buildFriendSection(),
            const SizedBox(height: 8),

            // 알림
            _SettingCard(
              icon: Icons.alarm_outlined,
              onTap: _showAlarmPicker,
              child: Row(
                children: [
                  const Text('알림', style: TextStyle(fontSize: 14)),
                  const Spacer(),
                  Text(_alarmLabel(),
                      style:
                          const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 반복
            _SettingCard(
              icon: Icons.repeat_outlined,
              onTap: _showRepeatPicker,
              child: Row(
                children: [
                  const Text('반복', style: TextStyle(fontSize: 14)),
                  const Spacer(),
                  Text(_repeatLabel(),
                      style:
                          const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // D-Day
            _SettingCard(
              icon: Icons.star_border_outlined,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('D-Day 설정', style: TextStyle(fontSize: 14)),
                  Switch(
                    value: _isDday,
                    onChanged: (v) => setState(() => _isDday = v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF7C6AFA),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 메모
            _SettingCard(
              icon: Icons.edit_note_outlined,
              child: TextFormField(
                controller: _memoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '메모를 입력하세요',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── 친구 태그 섹션 빌더 ────────────────────────────────────────────
  Widget _buildFriendSection() {
    // 합쳐보기에서 왔을 때: 프리필 친구들 칩 + 추가 친구 선택 가능
    if (_isFromMerge) {
      return _SettingCard(
        icon: Icons.people_outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프리필 친구 칩들 (삭제 가능)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ..._prefilledNames.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final name = entry.value;
                  return _FriendChip(
                    name: name,
                    onRemove: () {
                      setState(() {
                        _prefilledIds.removeAt(idx);
                        _prefilledNames.removeAt(idx);
                      });
                    },
                  );
                }),
                // 개별 선택 친구 (추가)
                if (_taggedFriend != null)
                  _FriendChip(
                    name: _taggedFriend!.friendProfile.nickname ?? '?',
                    onRemove: () => setState(() => _taggedFriend = null),
                  ),
                // 친구 추가 버튼
                GestureDetector(
                  onTap: _showFriendPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('추가',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 일반 모드: 기존 단일 친구 선택
    return _SettingCard(
      icon: Icons.person_add_alt_outlined,
      onTap: _taggedFriend == null ? _showFriendPicker : null,
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
                Text(_taggedFriend!.friendProfile.nickname ?? '',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _taggedFriend = null),
                  child: const Icon(Icons.close,
                      size: 16, color: Colors.grey),
                ),
              ],
            ),
    );
  }
}

// ── 합쳐보기 배너 ─────────────────────────────────────────────────────────────

class _MergeBanner extends StatelessWidget {
  const _MergeBanner({required this.names});
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final nameText = names.join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C6AFA), Color(0xFF9B8FFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nameText 와(과) 함께하는 일정',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '저장하면 초대장이 자동 발송돼요 ✉️',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 친구 칩 (프리필 다중 태그용) ───────────────────────────────────────────────

class _FriendChip extends StatelessWidget {
  const _FriendChip({required this.name, required this.onRemove});
  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5B50D6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close,
                size: 14, color: Color(0xFF9B8FFF)),
          ),
        ],
      ),
    );
  }
}

// ── 공통 헬퍼 위젯 ──────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87),
      );
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.child,
    this.onTap,
  });

  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(child: child),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final dateStr =
        '${value.year}년 ${value.month}월 ${value.day}일 (${weekdays[value.weekday % 7]})';

    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF7C6AFA)),
            ),
            child: child!,
          ),
        );
        if (date == null) return;
        onChanged(DateTime(
            date.year, date.month, date.day, value.hour, value.minute));
      },
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          Expanded(
            child: Text(dateStr,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const Icon(Icons.calendar_today_outlined,
              size: 16, color: Color(0xFF7C6AFA)),
        ],
      ),
    );
  }
}

// ── 반복 설정 바텀시트 ──────────────────────────────────────────────

class _RepeatPickerSheet extends StatefulWidget {
  const _RepeatPickerSheet({
    required this.initialType,
    required this.initialWeekday,
    required this.initialMonthDay,
    required this.startDate,
    required this.onChanged,
  });

  final RecurrenceType? initialType;
  final int? initialWeekday;
  final int? initialMonthDay;
  final DateTime startDate;
  final void Function(RecurrenceType? type, int? weekday, int? monthDay)
      onChanged;

  @override
  State<_RepeatPickerSheet> createState() => _RepeatPickerSheetState();
}

class _RepeatPickerSheetState extends State<_RepeatPickerSheet> {
  RecurrenceType? _type;
  int? _weekday;
  int? _monthDay;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _weekday = widget.initialWeekday ?? widget.startDate.weekday;
    _monthDay = widget.initialMonthDay ?? widget.startDate.day;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('반복 설정',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  _TypeChip(
                      label: '없음',
                      selected: _type == null,
                      onTap: () => setState(() => _type = null)),
                  _TypeChip(
                      label: '매일',
                      selected: _type == RecurrenceType.daily,
                      onTap: () =>
                          setState(() => _type = RecurrenceType.daily)),
                  _TypeChip(
                      label: '매주',
                      selected: _type == RecurrenceType.weekly,
                      onTap: () =>
                          setState(() => _type = RecurrenceType.weekly)),
                  _TypeChip(
                      label: '매월',
                      selected: _type == RecurrenceType.monthly,
                      onTap: () =>
                          setState(() => _type = RecurrenceType.monthly)),
                ],
              ),
              if (_type == RecurrenceType.weekly) ...[
                const SizedBox(height: 16),
                const Text('요일 선택',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (i) {
                    final wd = i + 1;
                    const names = ['월', '화', '수', '목', '금', '토', '일'];
                    final isSelected = _weekday == wd;
                    return GestureDetector(
                      onTap: () => setState(() => _weekday = wd),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7C6AFA)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(names[i],
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              if (_type == RecurrenceType.monthly) ...[
                const SizedBox(height: 16),
                const Text('날짜 선택',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: 31,
                  itemBuilder: (_, i) {
                    final day = i + 1;
                    final isSelected = _monthDay == day;
                    return GestureDetector(
                      onTap: () => setState(() => _monthDay = day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF7C6AFA)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('$day',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              )),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onChanged(_type, _weekday, _monthDay);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6AFA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7C6AFA) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : Colors.black87,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }
}

// ── 친구 선택 바텀시트 ──────────────────────────────────────────────

class _FriendPickerSheet extends ConsumerWidget {
  const _FriendPickerSheet({
    required this.onSelected,
    this.excludeIds = const [],
  });
  final ValueChanged<FriendEntity> onSelected;
  final List<String> excludeIds;

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
                final available =
                    friends.where((f) => !excludeIds.contains(f.friendId)).toList();
                if (available.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('추가할 수 있는 친구가 없어요',
                            style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  itemCount: available.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final f = available[i];
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
