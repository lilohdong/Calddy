import '../../domain/entities/report_entity.dart';

abstract class ReportRemoteDataSource {
  Future<void> report({
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
  });
}
