import '../../../../core/error/failures.dart';

/// 닉네임 Value Object
/// 규칙: 2~20자, 공백 없음, 한글/영문/숫자/언더스코어/하이픈만 허용
class Nickname {
  final String value;

  const Nickname._(this.value);

  static const int _minLength = 2;
  static const int _maxLength = 20;

  /// 허용 문자: 한글(가-힣), 영문(a-z A-Z), 숫자(0-9), 언더스코어(_), 하이픈(-)
  static final RegExp _allowedChars = RegExp(r'^[가-힣a-zA-Z0-9_\-]+$');
  static final RegExp _hasSpace = RegExp(r'\s');

  /// 유효한 닉네임이면 [Nickname] 인스턴스 반환, 아니면 [NicknameValidationFailure] throw
  factory Nickname(String raw) {
    final error = validate(raw);
    if (error != null) throw error;
    return Nickname._(raw);
  }

  /// 유효성 검사만 수행. 오류가 없으면 null, 있으면 [NicknameValidationFailure] 반환.
  static NicknameValidationFailure? validate(String raw) {
    if (_hasSpace.hasMatch(raw)) {
      return const NicknameValidationFailure('닉네임에 공백을 포함할 수 없습니다.');
    }
    if (raw.length < _minLength) {
      return const NicknameValidationFailure('닉네임은 최소 2자 이상이어야 합니다.');
    }
    if (raw.length > _maxLength) {
      return const NicknameValidationFailure('닉네임은 최대 20자까지 입력할 수 있습니다.');
    }
    if (!_allowedChars.hasMatch(raw)) {
      return const NicknameValidationFailure(
        '닉네임에는 한글, 영문, 숫자, 언더스코어(_), 하이픈(-)만 사용할 수 있습니다.',
      );
    }
    return null;
  }

  @override
  String toString() => value;
}
