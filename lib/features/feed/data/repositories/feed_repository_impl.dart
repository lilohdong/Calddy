import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/post_liker_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_datasource.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource _remoteDataSource;

  FeedRepositoryImpl({required FeedRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<PostEntity>> getFeedByDate(DateTime date, {DateTime? cursor}) async {
    try {
      return await _remoteDataSource.getFeedByDate(date, cursor: cursor);
    } on AuthException {
      throw const FeedSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const FeedUnknownFailure();
    }
  }

  @override
  Stream<List<CommentEntity>> watchComments(String postId) =>
      _remoteDataSource.watchComments(postId);

  @override
  Future<void> createPost({
    String? content,
    List<int>? imageBytes,
    String? imageExtension,
    required PostVisibility visibility,
    required DateTime feedDate,
    String? eventId,
  }) async {
    try {
      await _remoteDataSource.createPost(
        content: content,
        imageBytes: imageBytes,
        imageExtension: imageExtension,
        visibility: visibility == PostVisibility.public ? 'public' : 'private',
        feedDate: _dateStr(feedDate),
        eventId: eventId,
      );
    } on AuthException {
      throw const FeedSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const FeedUnknownFailure();
    }
  }

  @override
  Future<void> updatePost({
    required String postId,
    String? content,
    required PostVisibility visibility,
  }) async {
    try {
      await _remoteDataSource.updatePost(
        postId: postId,
        content: content,
        visibility: visibility == PostVisibility.public ? 'public' : 'private',
      );
    } on AuthException {
      throw const FeedSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const FeedUnknownFailure();
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await _remoteDataSource.deletePost(postId);
    } on AuthException {
      throw const FeedSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const FeedUnknownFailure();
    }
  }

  // ── P2 ────────────────────────────────────────────────────────────────────

  @override
  Future<void> togglePostLike({
    required String postId,
    required bool currentlyLiked,
  }) async {
    try {
      await _remoteDataSource.togglePostLike(
        postId: postId,
        currentlyLiked: currentlyLiked,
      );
    } on AuthException {
      throw const FeedSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const FeedUnknownFailure();
    }
  }

  @override
  Future<List<CommentEntity>> getComments(String postId) async {
    try {
      return await _remoteDataSource.getComments(postId);
    } on AuthException {
      throw const FeedSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const FeedUnknownFailure();
    }
  }

  @override
  Future<void> createComment({
    required String postId,
    required String content,
  }) async {
    try {
      await _remoteDataSource.createComment(postId: postId, content: content);
    } on AuthException {
      throw const FeedSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const FeedUnknownFailure();
    }
  }

  @override
  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      await _remoteDataSource.updateComment(
          commentId: commentId, content: content);
    } on AuthException {
      throw const FeedSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const FeedUnknownFailure();
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      await _remoteDataSource.deleteComment(commentId);
    } on AuthException {
      throw const FeedSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const FeedUnknownFailure();
    }
  }

  @override
  Future<List<PostLikerEntity>> getPostLikers(String postId) async {
    try {
      return await _remoteDataSource.getPostLikers(postId);
    } on AuthException {
      throw const FeedSessionExpiredFailure();
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const FeedUnknownFailure();
    }
  }

  FeedFailure _mapPostgrest(PostgrestException e) {
    switch (e.code) {
      case '23514':
        return const FeedContentRequiredFailure();
      default:
        return FeedDatabaseFailure(e.message);
    }
  }

  String _dateStr(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
