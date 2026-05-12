import 'package:flutter/material.dart';
import '../../domain/entities/friend_entity.dart';

class FriendListTile extends StatelessWidget {
  const FriendListTile({
    super.key,
    required this.friend,
    required this.onTap,
    required this.onMerge,
    required this.onDelete,
  });

  final FriendEntity friend;
  final VoidCallback onTap;    // 친구 캘린더
  final VoidCallback onMerge;  // 합쳐보기
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final profile = friend.friendProfile;
    return ListTile(
      leading: CircleAvatar(
        child: Text(profile.nickname?.isNotEmpty == true ? profile.nickname![0] : '?'),
      ),
      title: Text(profile.nickname ?? ''),
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.call_merge_outlined),
            tooltip: '합쳐보기',
            onPressed: onMerge,
          ),
          IconButton(
            icon: const Icon(Icons.person_remove_outlined),
            tooltip: '친구 삭제',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
