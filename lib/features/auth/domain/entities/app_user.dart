/// 인증된 사용자 정보를 나타내는 엔티티
class AppUser {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final bool isOnboarded;

  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.isOnboarded = false,
  });
}
