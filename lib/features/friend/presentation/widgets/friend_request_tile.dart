import 'package:flutter/material.dart';
import '../../domain/entities/friend_entity.dart';

class FriendRequestTile extends StatelessWidget {
  const FriendRequestTile({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
    this.isLoading = false,
  });

  final FriendRequestEntity request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final profile = request.requesterProfile;
    return ListTile(
      leading: CircleAvatar(
        child: Text(profile.nickname?.isNotEmpty == true ? profile.nickname![0] : '?'),
      ),
      title: Text(profile.nickname ?? ''),
      trailing: isLoading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(onPressed: onAccept, child: const Text('수락')),
                TextButton(onPressed: onReject, child: const Text('거절')),
              ],
            ),
    );
  }
}
