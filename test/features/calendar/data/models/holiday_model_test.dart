import 'package:calddy/features/calendar/data/models/holiday_model.dart';
import 'package:calddy/features/calendar/domain/entities/holiday_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HolidayModel', () {
    final json = {'date': '2026-01-01', 'name': '신정'};

    test('fromJson이 date와 name을 올바르게 파싱한다', () {
      final model = HolidayModel.fromJson(json);
      expect(model.date, DateTime(2026, 1, 1));
      expect(model.name, '신정');
    });

    test('toEntity가 HolidayEntity를 올바르게 반환한다', () {
      final model = HolidayModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity, isA<HolidayEntity>());
      expect(entity.date, DateTime(2026, 1, 1));
      expect(entity.name, '신정');
    });

    test('fromJson이 잘못된 날짜 형식이면 FormatException을 던진다', () {
      expect(
        () => HolidayModel.fromJson({'date': 'not-a-date', 'name': '테스트'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
