import 'package:calddy/features/map/data/models/midpoint_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MidpointResultModel.fromJson', () {
    test('유효한 JSON에서 MidpointResultModel 생성', () {
      final json = {
        'lat': 37.5,
        'lng': 127.0,
        'participants': [
          {'userId': 'user-1', 'nickname': '홍길동', 'travelMinutes': 30},
          {'userId': 'user-2', 'nickname': '김철수', 'travelMinutes': 45},
        ],
      };
      final model = MidpointResultModel.fromJson(json);
      expect(model.lat, 37.5);
      expect(model.lng, 127.0);
      expect(model.participants.length, 2);
      expect(model.participants.first.userId, 'user-1');
      expect(model.participants.first.travelMinutes, 30);
    });

    test('travelMinutes가 null인 참여자를 올바르게 파싱한다', () {
      final json = {
        'lat': 37.0,
        'lng': 127.0,
        'participants': [
          {'userId': 'user-1', 'nickname': '홍길동', 'travelMinutes': null},
        ],
      };
      final model = MidpointResultModel.fromJson(json);
      expect(model.participants.first.travelMinutes, isNull);
    });
  });
}
