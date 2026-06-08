import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/invite_entity.dart';
import '../../domain/usecases/accept_invite_use_case.dart';
import '../../domain/usecases/reject_invite_use_case.dart';
import '../providers/appointment_providers.dart';

class AppointmentDetailPage extends ConsumerStatefulWidget {
  const AppointmentDetailPage({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  ConsumerState<AppointmentDetailPage> createState() =>
      _AppointmentDetailPageState();
}

class _AppointmentDetailPageState
    extends ConsumerState<AppointmentDetailPage> {
  bool _isLoading = false;

  Future<void> _respond(String inviteId, bool accept) async {
    setState(() => _isLoading = true);
    try {
      if (accept) {
        await ref
            .read(acceptInviteUseCaseProvider)
            .call(AcceptInviteParams(inviteId: inviteId));
      } else {
        await ref
            .read(rejectInviteUseCaseProvider)
            .call(RejectInviteParams(inviteId: inviteId));
      }
      ref
        ..invalidate(myInvitesProvider)
        ..invalidate(appointmentDetailProvider(widget.appointmentId));
      if (mounted) context.pop();
    } on AppointmentFailure catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(accept ? '수락에 실패했습니다.' : '거절에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final appointmentAsync =
        ref.watch(appointmentDetailProvider(widget.appointmentId));
    final myInvitesAsync = ref.watch(myInvitesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('약속 상세')),
      body: appointmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text(
                e is AppointmentFailure ? e.message : '불러오기 실패')),
        data: (appointment) {
          // 나에게 온 초대 찾기
          final myInvite = myInvitesAsync.valueOrNull?.where(
            (i) => i.appointmentId == widget.appointmentId,
          ).firstOrNull;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 약속 정보
              _SectionCard(
                title: '약속 정보',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.event,
                      label: '일정',
                      value: appointment.eventTitle ?? '제목 없음',
                    ),
                    if (appointment.eventStartAt != null)
                      _InfoRow(
                        icon: Icons.access_time_outlined,
                        label: '일시',
                        value: _fmtRange(
                            appointment.eventStartAt!, appointment.eventEndAt),
                      ),
                    if (appointment.eventLocation != null &&
                        appointment.eventLocation!.isNotEmpty)
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: '장소',
                        value: appointment.eventLocation!,
                      ),
                    if (appointment.suggestedPlace != null)
                      _InfoRow(
                        icon: Icons.stars_outlined,
                        label: 'AI 추천 장소',
                        value: appointment.suggestedPlace!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 초대 현황
              _SectionCard(
                title: '초대 현황',
                child: Column(
                  children: appointment.invites
                      .map((inv) => _InviteTile(invite: inv))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),

              // 내 초대가 pending 상태일 때 수락/거절 버튼
              if (myInvite != null &&
                  myInvite.status == InviteStatus.pending) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _respond(myInvite.id, false),
                        child: const Text('거절'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _respond(myInvite.id, true),
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('수락'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _fmtRange(DateTime start, DateTime? end) {
  String fmt(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  if (end == null) return fmt(start);
  return '${fmt(start)} ~ ${fmt(end)}';
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _InviteTile extends StatelessWidget {
  const _InviteTile({required this.invite});
  final InviteEntity invite;

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (invite.status) {
      case InviteStatus.pending:
        statusColor = Colors.orange;
        statusText = '대기';
      case InviteStatus.accepted:
        statusColor = Colors.green;
        statusText = '수락';
      case InviteStatus.rejected:
        statusColor = Colors.red;
        statusText = '거절';
      case InviteStatus.cancelled:
        statusColor = Colors.grey;
        statusText = '취소';
    }

    final nickname = (invite.inviteeNickname?.isNotEmpty == true)
        ? invite.inviteeNickname!
        : '알 수 없음';
    final avatarUrl = invite.inviteeAvatarUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF7C6AFA).withValues(alpha: 0.15),
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7C6AFA),
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(nickname, style: const TextStyle(fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusText,
                style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
