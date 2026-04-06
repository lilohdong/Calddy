import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/auth/domain/value_objects/nickname.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nickname.validate', () {
    // ── 통과 케이스 ────────────────────────────────────────────
    group('유효한 닉네임', () {
      test('한글 2자', () => expect(Nickname.validate('홍길'), isNull));
      test('영문 소문자', () => expect(Nickname.validate('hello'), isNull));
      test('영문 대소문자 + 숫자', () => expect(Nickname.validate('User123'), isNull));
      test('한글 + 언더스코어', () => expect(Nickname.validate('홍길_동'), isNull));
      test('하이픈 포함', () => expect(Nickname.validate('hong-gil'), isNull));
      test('최대 20자', () => expect(Nickname.validate('가' * 20), isNull));
    });

    // ── 공백 ──────────────────────────────────────────────────
    group('공백 포함 시 실패', () {
      test('중간 공백', () {
        final err = Nickname.validate('hong gil');
        expect(err, isA<NicknameValidationFailure>());
        expect(err!.message, contains('공백'));
      });

      test('탭 문자', () {
        final err = Nickname.validate('hong\tgil');
        expect(err, isA<NicknameValidationFailure>());
      });
    });

    // ── 길이 ──────────────────────────────────────────────────
    group('길이 제약', () {
      test('1자 → 최소 길이 미달', () {
        final err = Nickname.validate('홍');
        expect(err, isA<NicknameValidationFailure>());
        expect(err!.message, contains('2자'));
      });

      test('빈 문자열 → 최소 길이 미달', () {
        final err = Nickname.validate('');
        expect(err, isA<NicknameValidationFailure>());
      });

      test('21자 → 최대 길이 초과', () {
        final err = Nickname.validate('가' * 21);
        expect(err, isA<NicknameValidationFailure>());
        expect(err!.message, contains('20자'));
      });
    });

    // ── 허용 문자 외 ────────────────────────────────────────────
    group('허용하지 않는 문자', () {
      test('느낌표', () {
        final err = Nickname.validate('hello!');
        expect(err, isA<NicknameValidationFailure>());
      });

      test('특수문자 @', () {
        final err = Nickname.validate('user@name');
        expect(err, isA<NicknameValidationFailure>());
      });

      test('이모지', () {
        final err = Nickname.validate('유저😀');
        expect(err, isA<NicknameValidationFailure>());
      });
    });

    // ── factory 생성자 ─────────────────────────────────────────
    group('factory 생성자', () {
      test('유효하면 Nickname 인스턴스 반환', () {
        expect(() => Nickname('홍길동'), returnsNormally);
        expect(Nickname('홍길동').value, '홍길동');
      });

      test('유효하지 않으면 NicknameValidationFailure throw', () {
        expect(() => Nickname('홍'), throwsA(isA<NicknameValidationFailure>()));
      });
    });
  });
}
