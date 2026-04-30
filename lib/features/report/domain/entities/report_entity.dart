enum ReportTargetType { post, comment, user }
enum ReportStatus { pending, reviewed }

class ReportEntity {
  final String id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;

  const ReportEntity({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });
}
