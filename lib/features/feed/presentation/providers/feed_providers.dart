import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/global_providers.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/datasources/feed_remote_datasource_impl.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/usecases/create_comment_usecase.dart';
import '../../domain/usecases/create_post_usecase.dart';
import '../../domain/usecases/delete_comment_usecase.dart';
import '../../domain/usecases/delete_post_usecase.dart';
import '../../domain/usecases/get_comments_usecase.dart';
import '../../domain/usecases/get_feed_by_date_usecase.dart';
import '../../domain/usecases/toggle_post_like_usecase.dart';
import '../../domain/usecases/update_comment_usecase.dart';
import '../../domain/usecases/update_post_usecase.dart';

// ── DataSource ────────────────────────────────────────────────────────────────

final feedRemoteDataSourceProvider = Provider<FeedRemoteDataSource>((ref) {
  return FeedRemoteDataSourceImpl(
    supabase: ref.watch(supabaseClientProvider),
  );
});

// ── Repository ────────────────────────────────────────────────────────────────

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(
    remoteDataSource: ref.watch(feedRemoteDataSourceProvider),
  );
});

// ── UseCases ──────────────────────────────────────────────────────────────────

final getFeedByDateUseCaseProvider = Provider<GetFeedByDateUseCase>((ref) {
  return GetFeedByDateUseCase(ref.watch(feedRepositoryProvider));
});

final createPostUseCaseProvider = Provider<CreatePostUseCase>((ref) {
  return CreatePostUseCase(ref.watch(feedRepositoryProvider));
});

final updatePostUseCaseProvider = Provider<UpdatePostUseCase>((ref) {
  return UpdatePostUseCase(ref.watch(feedRepositoryProvider));
});

final deletePostUseCaseProvider = Provider<DeletePostUseCase>((ref) {
  return DeletePostUseCase(ref.watch(feedRepositoryProvider));
});

final togglePostLikeUseCaseProvider = Provider<TogglePostLikeUseCase>((ref) {
  return TogglePostLikeUseCase(ref.watch(feedRepositoryProvider));
});

final getCommentsUseCaseProvider = Provider<GetCommentsUseCase>((ref) {
  return GetCommentsUseCase(ref.watch(feedRepositoryProvider));
});

final createCommentUseCaseProvider = Provider<CreateCommentUseCase>((ref) {
  return CreateCommentUseCase(ref.watch(feedRepositoryProvider));
});

final updateCommentUseCaseProvider = Provider<UpdateCommentUseCase>((ref) {
  return UpdateCommentUseCase(ref.watch(feedRepositoryProvider));
});

final deleteCommentUseCaseProvider = Provider<DeleteCommentUseCase>((ref) {
  return DeleteCommentUseCase(ref.watch(feedRepositoryProvider));
});

// ── State Providers ───────────────────────────────────────────────────────────

/// 날짜별 피드 — cursor 페이지네이션 지원
/// fetchMore()로 다음 페이지, refresh()로 새로고침
class FeedNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<PostEntity>, DateTime> {
  DateTime? _cursor;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  @override
  Future<List<PostEntity>> build(DateTime arg) async {
    _cursor = null;
    _hasMore = true;
    return _fetch(arg);
  }

  Future<List<PostEntity>> _fetch(DateTime date) async {
    final posts = await ref.read(getFeedByDateUseCaseProvider).call(
          GetFeedByDateParams(date: date, cursor: _cursor),
        );
    if (posts.length < 20) _hasMore = false;
    if (posts.isNotEmpty) _cursor = posts.last.createdAt;
    return posts;
  }

  /// 다음 페이지 로드 (스크롤 끝에서 호출)
  Future<void> fetchMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    final more = await _fetch(arg);
    state = AsyncData([...current, ...more]);
  }

  /// 새로고침 (pull-to-refresh에서 호출)
  Future<void> refresh() async {
    _cursor = null;
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

final feedByDateProvider = AsyncNotifierProvider.autoDispose
    .family<FeedNotifier, List<PostEntity>, DateTime>(FeedNotifier.new);

/// 댓글 Realtime 구독 (postId별)
final commentsStreamProvider = StreamProvider.autoDispose
    .family<List<CommentEntity>, String>((ref, postId) {
  return ref.watch(feedRepositoryProvider).watchComments(postId);
});

/// 게시물 댓글 단순 조회 (Realtime 불필요한 경우 대체 사용)
final commentsProvider = FutureProvider.autoDispose
    .family<List<CommentEntity>, String>((ref, postId) {
  return ref
      .watch(getCommentsUseCaseProvider)
      .call(GetCommentsParams(postId: postId));
});
