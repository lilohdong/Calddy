import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../domain/entities/post_entity.dart';
import '../models/post_model.dart';
import 'feed_remote_datasource.dart';

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final SupabaseClient _supabase;

  FeedRemoteDataSourceImpl({required SupabaseClient supabase})
      : _supabase = supabase;

  String get _currentUserId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const AuthException('session_expired');
    return id;
  }

  @override
  Future<List<PostEntity>> getFeedByDate(DateTime date) async {
    final dateStr = _dateStr(date);
    final results = await _supabase
        .from(SupabaseConstants.posts)
        .select(
          'id, user_id, event_id, content, image_url, visibility, likes_count, feed_date, created_at',
        )
        .eq('feed_date', dateStr)
        .order('created_at', ascending: false)
        .limit(20);

    return (results as List)
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createPost({
    String? content,
    List<int>? imageBytes,
    String? imageExtension,
    required String visibility,
    required String feedDate,
    String? eventId,
  }) async {
    final userId = _currentUserId;
    String? imageUrl;

    if (imageBytes != null && imageExtension != null) {
      final path =
          '$userId/${DateTime.now().millisecondsSinceEpoch}.$imageExtension';
      await _supabase.storage
          .from(SupabaseConstants.postsBucket)
          .uploadBinary(path, Uint8List.fromList(imageBytes));
      imageUrl = _supabase.storage
          .from(SupabaseConstants.postsBucket)
          .getPublicUrl(path);
    }

    await _supabase.from(SupabaseConstants.posts).insert({
      'user_id': userId,
      if (eventId != null) 'event_id': eventId,
      if (content != null) 'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
      'visibility': visibility,
      'feed_date': feedDate,
    });
  }

  @override
  Future<void> updatePost({
    required String postId,
    String? content,
    required String visibility,
  }) async {
    await _supabase
        .from(SupabaseConstants.posts)
        .update({
          'content': content,
          'visibility': visibility,
        })
        .eq('id', postId)
        .eq('user_id', _currentUserId);
  }

  @override
  Future<void> deletePost(String postId) async {
    final userId = _currentUserId;

    // image_url 먼저 조회해서 Storage 파일 삭제
    final row = await _supabase
        .from(SupabaseConstants.posts)
        .select('image_url')
        .eq('id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    final imageUrl = row?['image_url'] as String?;
    if (imageUrl != null) {
      final path = _extractStoragePath(imageUrl);
      if (path != null) {
        await _supabase.storage
            .from(SupabaseConstants.postsBucket)
            .remove([path]);
      }
    }

    await _supabase
        .from(SupabaseConstants.posts)
        .delete()
        .eq('id', postId)
        .eq('user_id', userId);
  }

  // URL에서 Storage 경로 추출: .../public/posts/userId/filename → userId/filename
  String? _extractStoragePath(String imageUrl) {
    final marker = '/object/public/${SupabaseConstants.postsBucket}/';
    final idx = imageUrl.indexOf(marker);
    if (idx == -1) return null;
    return imageUrl.substring(idx + marker.length);
  }

  String _dateStr(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
