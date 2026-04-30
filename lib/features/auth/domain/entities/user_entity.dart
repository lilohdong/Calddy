/// 인증된 사용자 정보 엔티티 (auth / user 피처 공용)
///
/// [isOnboarded] 는 라우팅 분기용 auth 전용 플래그로,
/// 온보딩 완료 전까지 false를 유지한다.
class UserEntity {
  final String id;           // auth.uid()
  final String email;
  final String? nickname;    // profiles.nickname (온보딩 전 null 가능)
  final String? avatarUrl;   // Supabase Storage URL
  final DateTime? birthDate;
  final bool pushEnabled;
  final String? fcmToken;
  final DateTime? createdAt;
  final bool isOnboarded;    // 온보딩 완료 여부 (라우팅 분기용)

  const UserEntity({
    required this.id,
    required this.email,
    this.nickname,
    this.avatarUrl,
    this.birthDate,
    this.pushEnabled = false,
    this.fcmToken,
    this.createdAt,
    this.isOnboarded = false,
  });
}
