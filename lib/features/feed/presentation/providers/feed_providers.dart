import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/global_providers.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/datasources/feed_remote_datasource_impl.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/usecases/create_post_usecase.dart';
import '../../domain/usecases/delete_post_usecase.dart';
import '../../domain/usecases/get_feed_by_date_usecase.dart';
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

// ── State Providers ───────────────────────────────────────────────────────────

/// 날짜별 피드 (날짜가 바뀌면 자동 해제)
final feedByDateProvider = FutureProvider.autoDispose
    .family<List<PostEntity>, DateTime>((ref, date) {
  return ref
      .watch(getFeedByDateUseCaseProvider)
      .call(GetFeedByDateParams(date: date));
});
