import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../models/comment_model.dart';
import '../models/post_liker_model.dart';
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
  Future<List<PostModel>> getFeedByDate(DateTime date, {DateTime? cursor}) async {
    final userId = _currentUserId;
    final dateStr = _dateStr(date);

    var filterQuery = _supabase
        .from(SupabaseConstants.posts)
        .select(
          'id, user_id, event_id, content, image_url, visibility, likes_count, feed_date, created_at, profiles!posts_user_id_fkey(nickname, avatar_url)',
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
  Future<PostModel> getPostById(String postId) async {
    final userId = _currentUserId;

    final result = await _supabase
        .from(SupabaseConstants.posts)
        .select(
          'id, user_id, event_id, content, image_url, visibility, likes_count, feed_date, created_at, profiles!posts_user_id_fkey(nickname, avatar_url)',
        )
        .eq('id', postId)
        .single();

    final likedResult = await _supabase
        .from(SupabaseConstants.postLikes)
        .select('post_id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    return PostModel.fromJson(
      result,
      isLikedByMe: likedResult != null,
    );
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
    await _supabase.functions.invoke(
      'delete-post',
      body: {'post_id': postId},
    );
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
  Future<List<CommentModel>> getComments(String postId) async {
    final results = await _supabase
        .from(SupabaseConstants.comments)
        .select('id, post_id, user_id, content, created_at, profiles!comments_user_id_fkey(nickname)')
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
  Stream<List<CommentModel>> watchComments(String postId) {
    final controller = StreamController<List<CommentModel>>.broadcast();

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

  @override
  Future<List<PostLikerModel>> getPostLikers(String postId) async {
    final userId = _currentUserId;

    final results = await _supabase
        .from(SupabaseConstants.postLikes)
        .select('user_id, profiles!post_likes_user_id_fkey(nickname, avatar_url)')
        .eq('post_id', postId)
        .order('created_at');

    final likers = results as List;
    if (likers.isEmpty) return [];

    // 좋아요 누른 사람들 중 내 친구인지 일괄 확인
    final likerIds = likers.map((l) => l['user_id'] as String).toList();
    final friendResults = await _supabase
        .from(SupabaseConstants.friends)
        .select('friend_id')
        .eq('user_id', userId)
        .inFilter('friend_id', likerIds);

    final friendIds = {
      for (final f in friendResults as List) f['friend_id'] as String,
    };

    return likers
        .map((json) => PostLikerModel.fromJson(
              json as Map<String, dynamic>,
              isFriend: friendIds.contains(json['user_id'] as String),
            ))
        .toList();
  }

  String _dateStr(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
