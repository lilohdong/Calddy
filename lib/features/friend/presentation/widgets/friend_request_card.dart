import 'package:flutter/material.dart';
import '../../domain/entities/friend_entity.dart';

class FriendRequestCard extends StatelessWidget {
  const FriendRequestCard({
    super.key,
    required this.requests,
    required this.loadingIds,
    required this.onAccept,
    required this.onReject,
  });

  final List<FriendRequestEntity> requests;
  final Set<String> loadingIds;
  final void Function(String requestId) onAccept;
  final void Function(String requestId) onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4CCFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF7C6AFA),
                  ),
                  child: Center(
                    child: Text(
                      '${requests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '새로운 친구 요청',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF5B50D6),
                  ),
                ),
              ],
            ),
          ),
          ...requests.map((req) => _RequestRow(
                request: req,
                isLoading: loadingIds.contains(req.id),
                onAccept: () => onAccept(req.id),
                onReject: () => onReject(req.id),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.isLoading,
    required this.onAccept,
    required this.onReject,
  });

  final FriendRequestEntity request;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final profile = request.requesterProfile;
    final nickname = profile.nickname ?? '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF9B8FF5).withOpacity(0.2),
            child: Text(
              nickname.isNotEmpty ? nickname[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9B8FF5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nickname,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              children: [
                _ActionBtn(label: '수락', isPrimary: true, onTap: onAccept),
                const SizedBox(width: 8),
                _ActionBtn(label: '거절', isPrimary: false, onTap: onReject),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF7C6AFA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.white : Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
