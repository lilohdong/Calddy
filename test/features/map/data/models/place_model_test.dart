import 'package:calddy/features/map/data/models/place_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaceModel.fromJson', () {
    test('유효한 JSON에서 PlaceModel 생성', () {
      final json = {
        'placeId': 'place-1',
        'name': '스타벅스',
        'address': '서울 강남구',
        'lat': 37.5,
        'lng': 127.0,
        'distanceFromMidpoint': 250.5,
      };
      final model = PlaceModel.fromJson(json);
      expect(model.placeId, 'place-1');
      expect(model.name, '스타벅스');
      expect(model.address, '서울 강남구');
      expect(model.lat, 37.5);
      expect(model.lng, 127.0);
      expect(model.distanceFromMidpoint, 250.5);
    });

    test('int 타입 숫자도 double로 파싱한다', () {
      final json = {
        'placeId': 'place-2',
        'name': '카페',
        'address': '서울',
        'lat': 37,
        'lng': 127,
        'distanceFromMidpoint': 100,
      };
      final model = PlaceModel.fromJson(json);
      expect(model.lat, isA<double>());
      expect(model.lng, isA<double>());
      expect(model.distanceFromMidpoint, isA<double>());
    });
  });
}
