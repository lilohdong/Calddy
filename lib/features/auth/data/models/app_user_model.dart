import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';

/// 데이터 소스로부터 전달받은 사용자 정보 모델
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    super.name,
    super.avatarUrl,
    super.isOnboarded,
  });

  /// Supabase의 User 객체와 profiles 테이블 데이터를 결합하여 모델 생성
  factory AppUserModel.fromSupabase(User user, Map<String, dynamic>? profileData) {
    return AppUserModel(
      id: user.id,
      email: user.email ?? '',
      name: profileData?['nickname'] as String? ?? user.userMetadata?['full_name'] as String?,
      avatarUrl: profileData?['avatar_url'] as String? ?? user.userMetadata?['avatar_url'] as String?,
      isOnboarded: profileData?['is_onboarded'] as bool? ?? false,
    );
  }

  /// 일반 User 정보가 없는 경우 빈 모델 생성 (필요 시)
  factory AppUserModel.empty() {
    return const AppUserModel(id: '', email: '');
  }
}
