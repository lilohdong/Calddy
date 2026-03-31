import '../entities/app_user.dart';

/// 인증 기능을 담당하는 리포지토리 인터페이스
abstract class AuthRepository {
  /// 구글 계정을 이용한 로그인
  Future<AppUser?> signInWithGoogle();

  /// 이메일/비밀번호를 이용한 회원가입
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
  });

  /// 이메일/비밀번호를 이용한 로그인
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  });

  /// 현재 로그인된 사용자 정보 조회
  Future<AppUser?> getCurrentUser();

  /// 로그아웃
  Future<void> signOut();

  /// 세션 상태 변화 감지 스트림
  Stream<AppUser?> get authStateChanges;
}
