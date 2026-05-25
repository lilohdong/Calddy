import 'package:calddy/features/map/data/models/place_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaceModel.fromJson', () {
    test('distanceFromMidpoint 포함 JSON을 올바르게 파싱한다', () {
      final json = {
        'placeId': 'p1',
        'name': '스타벅스 강남점',
        'address': '서울시 강남구',
        'lat': 37.498,
        'lng': 127.027,
        'distanceFromMidpoint': 350.5,
      };

      final model = PlaceModel.fromJson(json);

      expect(model.placeId, 'p1');
      expect(model.name, '스타벅스 강남점');
      expect(model.lat, 37.498);
      expect(model.distanceFromMidpoint, 350.5);
    });

    test('distanceFromMidpoint가 null인 JSON도 파싱한다', () {
      final json = {
        'placeId': 'p2',
        'name': '카페베네',
        'address': '서울시 서초구',
        'lat': 37.5,
        'lng': 127.0,
      };

      final model = PlaceModel.fromJson(json);

      expect(model.distanceFromMidpoint, isNull);
    });
  });
}
