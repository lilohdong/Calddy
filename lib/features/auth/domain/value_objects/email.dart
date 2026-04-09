import '../../../../core/error/failures.dart';

/// 이메일 Value Object
/// 규칙: RFC 5322 기반의 간이 정규식 검증
class Email {
  final String value;

  const Email._(this.value);

  static final RegExp _pattern = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  /// 유효한 이메일이면 [Email] 인스턴스 반환, 아니면 [EmailValidationFailure] throw
  factory Email(String raw) {
    final error = validate(raw);
    if (error != null) throw error;
    return Email._(raw);
  }

  /// 유효성 검사만 수행. 오류가 없으면 null, 있으면 [EmailValidationFailure] 반환.
  static EmailValidationFailure? validate(String raw) {
    if (!_pattern.hasMatch(raw)) {
      return const EmailValidationFailure();
    }
    return null;
  }

  @override
  String toString() => value;
}
