class ProfileEntity {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final DateTime? birthDate;
  final bool pushEnabled;

  const ProfileEntity({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    this.birthDate,
    this.pushEnabled = false,
  });
}
