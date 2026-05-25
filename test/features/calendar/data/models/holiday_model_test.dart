import 'package:calddy/features/calendar/data/models/holiday_model.dart';
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
      expect(entity.date, DateTime(2026, 1, 1));
      expect(entity.name, '신정');
    });
  });
}
