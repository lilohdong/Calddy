import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../models/comment_model.dart';
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
  Future<List<PostEntity>> getFeedByDate(DateTime date, {DateTime? cursor}) async {
    final userId = _currentUserId;
    final dateStr = _dateStr(date);

    var filterQuery = _supabase
        .from(SupabaseConstants.posts)
        .select(
          'id, user_id, event_id, content, image_url, visibility, likes_count, feed_date, created_at',
        )
        .eq('feed_date', dateStr);

    if (cursor != null) {
      filterQuery = filterQuery.lt('created_at', cursor.toIso8601String());
    }

    final results = await filterQuery
        .order('created_at', ascending: false)
        .limit(20);

    final posts = results as List;
    if (posts.isEmpty) return [];

    // isLikedByMe: 본인 좋아요 일괄 조회 (Friend inFilter 패턴)
    final postIds = posts.map((p) => p['id'] as String).toList();
    final likedResults = await _supabase
        .from(SupabaseConstants.postLikes)
        .select('post_id')
        .eq('user_id', userId)
        .inFilter('post_id', postIds);

    final likedIds = {
      for (final r in likedResults as List) r['post_id'] as String,
    };

    return posts
        .map((json) => PostModel.fromJson(
              json as Map<String, dynamic>,
              isLikedByMe: likedIds.contains(json['id'] as String),
            ))
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
      'event_id': eventId,
      'content': content,
      'image_url': imageUrl,
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

  // ── P2 ────────────────────────────────────────────────────────────────────

  @override
  Future<void> togglePostLike({
    required String postId,
    required bool currentlyLiked,
  }) async {
    final userId = _currentUserId;
    if (currentlyLiked) {
      await _supabase
          .from(SupabaseConstants.postLikes)
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      await _supabase.from(SupabaseConstants.postLikes).insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  @override
  Future<List<CommentEntity>> getComments(String postId) async {
    final results = await _supabase
        .from(SupabaseConstants.comments)
        .select('id, post_id, user_id, content, created_at')
        .eq('post_id', postId)
        .order('created_at');

    return (results as List)
        .map((json) => CommentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createComment({
    required String postId,
    required String content,
  }) async {
    await _supabase.from(SupabaseConstants.comments).insert({
      'post_id': postId,
      'user_id': _currentUserId,
      'content': content,
    });
  }

  @override
  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    await _supabase
        .from(SupabaseConstants.comments)
        .update({'content': content})
        .eq('id', commentId)
        .eq('user_id', _currentUserId);
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _supabase
        .from(SupabaseConstants.comments)
        .delete()
        .eq('id', commentId)
        .eq('user_id', _currentUserId);
  }

  @override
  Stream<List<CommentEntity>> watchComments(String postId) {
    final controller = StreamController<List<CommentEntity>>();

    // 초기 데이터 즉시 로드
    getComments(postId).then((comments) {
      if (!controller.isClosed) controller.add(comments);
    });

    // Realtime 구독: INSERT / UPDATE / DELETE 모두 감지
    final channel = _supabase
        .channel('comments:$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.comments,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: postId,
          ),
          callback: (_) async {
            final comments = await getComments(postId);
            if (!controller.isClosed) controller.add(comments);
          },
        )
        .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
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
