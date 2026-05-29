import 'package:flutter/material.dart';

import '../../domain/entities/post_entity.dart';

// ── 아바타 팔레트 ──────────────────────────────────────────────────────────────

const kAvatarColors = [
  Color(0xFF7C6AFA),
  Color(0xFFFF7043),
  Color(0xFF26A69A),
  Color(0xFFEC407A),
  Color(0xFF42A5F5),
  Color(0xFF66BB6A),
  Color(0xFFAB47BC),
  Color(0xFF26C6DA),
];

Color avatarColor(String userId) =>
    kAvatarColors[userId.hashCode.abs() % kAvatarColors.length];

String avatarInitial(String userId) =>
    userId.isNotEmpty ? userId[0].toUpperCase() : '?';

// ── 시간 포맷 ──────────────────────────────────────────────────────────────────

String fmtRelative(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.isNegative) return '방금 전';
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  return '${diff.inDays}일 전';
}

// ── 공개 범위 라벨 ────────────────────────────────────────────────────────────

bool isPrivatePost(PostEntity post) =>
    post.visibility == PostVisibility.private;
