/// 중간지점 직접 계산 시 참여자 위치 입력 모델
///
/// Riverpod family 키로 List를 직접 쓰면 참조 동등성 문제로 무한 재시작이 발생함.
/// [listToKey]로 JSON 문자열로 직렬화해 키로 사용할 것.
class LocationInput {
  final String userId;
  final String nickname;
  final String address;

  const LocationInput({
    required this.userId,
    required this.nickname,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'nickname': nickname,
        'address': address,
      };

  factory LocationInput.fromJson(Map<String, dynamic> json) => LocationInput(
        userId: json['userId'] as String,
        nickname: json['nickname'] as String,
        address: json['address'] as String,
      );

  /// List<LocationInput> → JSON String (Riverpod family 키용)
  static String listToKey(List<LocationInput> locations) =>
      locations.map((l) => l.toJson()).toList().toString();
}
