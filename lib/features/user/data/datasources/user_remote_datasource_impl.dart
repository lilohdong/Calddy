import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../models/profile_model.dart';
import 'user_remote_datasource.dart';

class NicknameOnCooldownException implements Exception {}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final SupabaseClient _client;

  UserRemoteDataSourceImpl(this._client);

  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('session_expired');
    return id;
  }

  @override
  Future<ProfileModel> getProfile(String userId) async {
    final result = await _client
        .from(SupabaseConstants.profiles)
        .select('id, nickname, avatar_url, birth_date, push_enabled')
        .eq('id', userId)
        .single();

    return ProfileModel.fromJson(result);
  }

  @override
  Future<void> updateNickname(String nickname) async {
    final userId = _currentUserId;

    final row = await _client
        .from(SupabaseConstants.profiles)
        .select('nickname_changed_at')
        .eq('id', userId)
        .single();

    final changedAtRaw = row['nickname_changed_at'] as String?;
    if (changedAtRaw != null) {
      final changedAt = DateTime.parse(changedAtRaw);
      if (DateTime.now().difference(changedAt).inDays < 30) {
        throw NicknameOnCooldownException();
      }
    }

    await _client
        .from(SupabaseConstants.profiles)
        .update({
          'nickname': nickname,
          'nickname_changed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> updateBirthDate(DateTime birthDate) async {
    final dateStr =
        '${birthDate.year.toString().padLeft(4, '0')}-'
        '${birthDate.month.toString().padLeft(2, '0')}-'
        '${birthDate.day.toString().padLeft(2, '0')}';

    await _client
        .from(SupabaseConstants.profiles)
        .update({'birth_date': dateStr})
        .eq('id', _currentUserId);
  }

  @override
  Future<String?> updateAvatar(String filePath) async {
    final userId = _currentUserId;
    final file = File(filePath);
    final dotIndex = filePath.lastIndexOf('.');
    final extension =
        dotIndex >= 0 ? filePath.substring(dotIndex + 1).toLowerCase() : 'jpg';
    final newStoragePath = '$userId/avatar.$extension';

    // 기존 아바타 삭제 (best-effort: 실패해도 업로드 계속)
    try {
      final profileRow = await _client
          .from(SupabaseConstants.profiles)
          .select('avatar_url')
          .eq('id', userId)
          .single();
      final oldUrl = profileRow['avatar_url'] as String?;
      final oldPath = _extractAvatarStoragePath(oldUrl);
      if (oldPath != null && oldPath != newStoragePath) {
        await _client.storage
            .from(SupabaseConstants.avatarsBucket)
            .remove([oldPath]);
      }
    } catch (_) {}

    await _client.storage
        .from(SupabaseConstants.avatarsBucket)
        .upload(
          newStoragePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = _client.storage
        .from(SupabaseConstants.avatarsBucket)
        .getPublicUrl(newStoragePath);

    await _client
        .from(SupabaseConstants.profiles)
        .update({'avatar_url': publicUrl})
        .eq('id', userId);

    return publicUrl;
  }

  static String? _extractAvatarStoragePath(String? url) {
    if (url == null) return null;
    const marker = '/avatars/';
    final idx = url.indexOf(marker);
    if (idx < 0) return null;
    return url.substring(idx + marker.length);
  }

  @override
  Future<void> setPushNotification({
    required bool enabled,
    String? fcmToken,
  }) async {
    final updates = <String, dynamic>{'push_enabled': enabled};
    if (fcmToken != null) updates['fcm_token'] = fcmToken;

    await _client
        .from(SupabaseConstants.profiles)
        .update(updates)
        .eq('id', _currentUserId);
  }

  @override
  Future<void> withdraw() async {
    await _client.functions.invoke('delete-account');
  }
}
