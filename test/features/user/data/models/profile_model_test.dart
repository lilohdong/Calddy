import 'package:calddy/features/user/data/models/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileModel.fromJson', () {
    test('전체 필드가 있는 JSON을 올바르게 파싱한다', () {
      final json = {
        'id': 'user-1',
        'nickname': '동준',
        'avatar_url': 'https://example.com/avatar.jpg',
        'birth_date': '1998-06-15',
        'push_enabled': false,
      };

      final model = ProfileModel.fromJson(json);

      expect(model.id, 'user-1');
      expect(model.nickname, '동준');
      expect(model.avatarUrl, 'https://example.com/avatar.jpg');
      expect(model.birthDate, DateTime(1998, 6, 15));
      expect(model.pushEnabled, false);
    });

    test('avatar_url이 null이면 avatarUrl은 null이다', () {
      final json = {
        'id': 'user-1',
        'nickname': '동준',
        'avatar_url': null,
        'birth_date': null,
        'push_enabled': true,
      };

      final model = ProfileModel.fromJson(json);

      expect(model.avatarUrl, isNull);
    });

    test('birth_date가 null이면 birthDate는 null이다', () {
      final json = {
        'id': 'user-1',
        'nickname': '동준',
        'birth_date': null,
        'push_enabled': true,
      };

      final model = ProfileModel.fromJson(json);

      expect(model.birthDate, isNull);
    });

    test('push_enabled가 null이면 기본값 true이다', () {
      final json = {
        'id': 'user-1',
        'nickname': '동준',
        'push_enabled': null,
      };

      final model = ProfileModel.fromJson(json);

      expect(model.pushEnabled, true);
    });

    test('nickname이 null이면 빈 문자열이다', () {
      final json = {
        'id': 'user-1',
        'nickname': null,
        'push_enabled': true,
      };

      final model = ProfileModel.fromJson(json);

      expect(model.nickname, '');
    });
  });
}
