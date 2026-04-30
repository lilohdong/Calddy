import '../entities/report_entity.dart';

abstract class ReportRepository {
  Future<void> report({
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
  });
}
