import '../../../../core/error/failures.dart';

/// 비밀번호 Value Object
/// 규칙: 공백 없음, 특수문자 포함, 최소 8자
class Password {
  final String value;

  const Password._(this.value);

  static const int _minLength = 8;
  static final RegExp _specialChar = RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]');
  static final RegExp _hasSpace = RegExp(r'\s');

  /// 유효한 비밀번호이면 [Password] 인스턴스 반환, 아니면 [PasswordValidationFailure] throw
  factory Password(String raw) {
    final error = validate(raw);
    if (error != null) throw error;
    return Password._(raw);
  }

  /// 유효성 검사만 수행. 오류가 없으면 null, 있으면 [PasswordValidationFailure] 반환.
  static PasswordValidationFailure? validate(String raw) {
    if (_hasSpace.hasMatch(raw)) {
      return const PasswordValidationFailure('비밀번호에 공백을 포함할 수 없습니다.');
    }
    if (raw.length < _minLength) {
      return const PasswordValidationFailure('비밀번호는 최소 8자 이상이어야 합니다.');
    }
    if (!_specialChar.hasMatch(raw)) {
      return const PasswordValidationFailure('비밀번호에 특수문자(!@#\$%^&* 등)를 포함해야 합니다.');
    }
    return null;
  }

  @override
  String toString() => value;
}
