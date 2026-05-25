import '../../domain/entities/holiday_entity.dart';

class HolidayModel {
  final DateTime date;
  final String name;

  const HolidayModel({required this.date, required this.name});

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    try {
      return HolidayModel(
        date: DateTime.parse(json['date'] as String),
        name: json['name'] as String,
      );
    } catch (e) {
      throw FormatException('HolidayModel.fromJson 파싱 실패: $e, json=$json');
    }
  }

  HolidayEntity toEntity() => HolidayEntity(date: date, name: name);
}
