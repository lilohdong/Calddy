import 'package:calddy/features/map/data/models/midpoint_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MidpointResultModel.fromJson', () {
    test('참여자 포함 JSON을 올바르게 파싱한다', () {
      final json = {
        'lat': 37.5,
        'lng': 127.0,
        'participants': [
          {'userId': 'u1', 'nickname': '동준', 'travelMinutes': 24},
          {'userId': 'u2', 'nickname': '지현', 'travelMinutes': null},
        ],
      };

      final model = MidpointResultModel.fromJson(json);

      expect(model.lat, 37.5);
      expect(model.participants.length, 2);
      expect(model.participants[0].travelMinutes, 24);
      expect(model.participants[1].travelMinutes, isNull);
    });

    test('travelMinutes가 double(24.0)이어도 int로 변환된다', () {
      final json = {
        'lat': 37.5,
        'lng': 127.0,
        'participants': [
          {'userId': 'u1', 'nickname': '동준', 'travelMinutes': 24.0},
        ],
      };

      final model = MidpointResultModel.fromJson(json);

      expect(model.participants[0].travelMinutes, 24);
    });

    test('participants 키가 없으면 빈 리스트로 파싱한다', () {
      final json = {'lat': 37.5, 'lng': 127.0};

      final model = MidpointResultModel.fromJson(json);

      expect(model.participants, isEmpty);
    });
  });
}
