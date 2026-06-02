/// 중간지점 직접 계산 시 참여자 위치 입력 모델
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
}
