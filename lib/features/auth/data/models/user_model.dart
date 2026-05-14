import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

/// 데이터 소스로부터 전달받은 사용자 정보 모델
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.nickname,
    super.avatarUrl,
    super.birthDate,
    super.pushEnabled,
    super.fcmToken,
    super.createdAt,
    super.isOnboarded,
    super.termsAgreedAt,
    super.termsVersion,
  });

  /// Supabase의 User 객체와 profiles 테이블 데이터를 결합하여 모델 생성
  factory UserModel.fromSupabase(User user, Map<String, dynamic>? profile) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      nickname: profile?['nickname'] as String? ??
          user.userMetadata?['full_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String? ??
          user.userMetadata?['avatar_url'] as String?,
      birthDate: profile?['birth_date'] != null
          ? DateTime.tryParse(profile!['birth_date'] as String)
          : null,
      pushEnabled: profile?['push_enabled'] as bool? ?? false,
      fcmToken: profile?['fcm_token'] as String?,
      createdAt: profile?['created_at'] != null
          ? DateTime.tryParse(profile!['created_at'] as String)
          : null,
      isOnboarded: profile?['is_onboarded'] as bool? ?? false,
      termsAgreedAt: profile?['terms_agreed_at'] != null
          ? DateTime.tryParse(profile!['terms_agreed_at'] as String)
          : null,
      termsVersion: profile?['terms_version'] as String?,
    );
  }
}
