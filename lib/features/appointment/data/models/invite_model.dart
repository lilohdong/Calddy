import '../../domain/entities/invite_entity.dart';

class InviteModel extends InviteEntity {
  const InviteModel({
    required super.id,
    required super.appointmentId,
    required super.inviteeId,
    required super.status,
    required super.updatedAt,
  });

  factory InviteModel.fromJson(Map<String, dynamic> json) => InviteModel(
        id: json['id'] as String,
        appointmentId: json['appointment_id'] as String,
        inviteeId: json['invitee_id'] as String,
        status: InviteStatus.values.byName(json['status'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  factory InviteModel.fromEntity(InviteEntity e) => InviteModel(
        id: e.id,
        appointmentId: e.appointmentId,
        inviteeId: e.inviteeId,
        status: e.status,
        updatedAt: e.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'appointment_id': appointmentId,
        'invitee_id': inviteeId,
        'status': status.name,
      };
}
