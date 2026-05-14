enum InviteStatus { pending, accepted, rejected, cancelled }

class InviteEntity {
  final String id;
  final String appointmentId;
  final String inviteeId;
  final InviteStatus status;
  final DateTime updatedAt;

  const InviteEntity({
    required this.id,
    required this.appointmentId,
    required this.inviteeId,
    required this.status,
    required this.updatedAt,
  });
}
