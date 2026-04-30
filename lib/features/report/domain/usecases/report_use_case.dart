import '../../../../core/usecase/usecase.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class ReportParams {
  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  const ReportParams({
    required this.targetType,
    required this.targetId,
    required this.reason,
  });
}

class ReportUseCase implements UseCase<void, ReportParams> {
  final ReportRepository _repository;
  ReportUseCase(this._repository);

  @override
  Future<void> call(ReportParams params) => _repository.report(
        targetType: params.targetType,
        targetId: params.targetId,
        reason: params.reason,
      );
}
