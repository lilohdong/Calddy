import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/auth/domain/value_objects/password.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Password.validate', () {
    // ── 통과 케이스 ────────────────────────────────────────────
    group('유효한 비밀번호', () {
      test('8자 이상 + 특수문자', () => expect(Password.validate('abc!1234'), isNull));
      test('긴 비밀번호', () => expect(Password.validate('LongP@ssword123'), isNull));
      test('다양한 특수문자 #', () => expect(Password.validate('pass#word1'), isNull));
      test('특수문자 언더스코어', () => expect(Password.validate('pass_word1'), isNull));
    });

    // ── 공백 ──────────────────────────────────────────────────
    group('공백 포함 시 실패', () {
      test('중간 공백', () {
        final err = Password.validate('pass word!');
        expect(err, isA<PasswordValidationFailure>());
        expect(err!.message, contains('공백'));
      });

      test('앞 공백', () {
        final err = Password.validate(' pass!123');
        expect(err, isA<PasswordValidationFailure>());
      });
    });

    // ── 길이 ──────────────────────────────────────────────────
    group('길이 제약', () {
      test('7자 → 최소 미달', () {
        final err = Password.validate('abc!123');
        expect(err, isA<PasswordValidationFailure>());
        expect(err!.message, contains('8자'));
      });

      test('빈 문자열', () {
        final err = Password.validate('');
        expect(err, isA<PasswordValidationFailure>());
      });
    });

    // ── 특수문자 ─────────────────────────────────────────────
    group('특수문자 누락 시 실패', () {
      test('영숫자만 8자', () {
        final err = Password.validate('abcd1234');
        expect(err, isA<PasswordValidationFailure>());
        expect(err!.message, contains('특수문자'));
      });
    });

    // ── factory 생성자 ─────────────────────────────────────────
    group('factory 생성자', () {
      test('유효하면 Password 인스턴스 반환', () {
        expect(() => Password('Valid!123'), returnsNormally);
        expect(Password('Valid!123').value, 'Valid!123');
      });

      test('유효하지 않으면 PasswordValidationFailure throw', () {
        expect(() => Password('short'), throwsA(isA<PasswordValidationFailure>()));
      });
    });
  });
}
