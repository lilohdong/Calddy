import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/global_providers.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../../data/datasources/report_remote_datasource_impl.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/usecases/report_use_case.dart';

// ── DataSource ────────────────────────────────────────────────────────────────

final reportRemoteDataSourceProvider = Provider<ReportRemoteDataSource>((ref) {
  return ReportRemoteDataSourceImpl(
    supabase: ref.watch(supabaseClientProvider),
  );
});

// ── Repository ────────────────────────────────────────────────────────────────

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(
    remoteDataSource: ref.watch(reportRemoteDataSourceProvider),
  );
});

// ── UseCase ───────────────────────────────────────────────────────────────────

final reportUseCaseProvider = Provider<ReportUseCase>((ref) {
  return ReportUseCase(ref.watch(reportRepositoryProvider));
});
