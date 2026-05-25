import 'package:flutter/material.dart';
import '../../domain/entities/searched_user_entity.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.user,
    required this.onSendRequest,
    required this.onAcceptRequest,
    required this.onCancelRequest,
    this.isLoading = false,
  });

  final SearchedUserEntity user;
  final VoidCallback onSendRequest;
  final VoidCallback onAcceptRequest;
  final VoidCallback onCancelRequest;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(user.nickname.isNotEmpty ? user.nickname[0] : '?'),
      ),
      title: Text(user.nickname),
      subtitle: user.bio != null ? Text(user.bio!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
      trailing: isLoading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : _actionButton(),
    );
  }

  Widget _actionButton() {
    return switch (user.relationStatus) {
      FriendRelationStatus.none         => IconButton(icon: const Icon(Icons.person_add_outlined), onPressed: onSendRequest),
      FriendRelationStatus.requestSent  => TextButton(onPressed: onCancelRequest, child: const Text('요청 취소', style: TextStyle(color: Colors.grey))),
      FriendRelationStatus.requestReceived => TextButton(onPressed: onAcceptRequest, child: const Text('수락')),
      FriendRelationStatus.friend       => const Icon(Icons.check, color: Colors.green),
    };
  }
}
