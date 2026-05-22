import '../../domain/entities/free_slot_entity.dart';

class FreeSlotModel extends FreeSlotEntity {
  const FreeSlotModel({required super.startAt, required super.endAt});

  factory FreeSlotModel.fromJson(Map<String, dynamic> json) {
    return FreeSlotModel(
      startAt: DateTime.parse(json['slot_start'] as String),
      endAt: DateTime.parse(json['slot_end'] as String),
    );
  }
}
