import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_datasource.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;

  ReportRepositoryImpl({required ReportRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<void> report({
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
  }) async {
    try {
      await _remoteDataSource.report(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
      );
    } on AuthException {
      throw const ReportSessionExpiredFailure();
    } on PostgrestException catch (e) {
      // UNIQUE 제약 위반 (이미 신고한 대상)
      if (e.code == '23505') throw const ReportDuplicateFailure();
      throw ReportUnknownFailure();
    } catch (_) {
      throw const ReportUnknownFailure();
    }
  }
}
