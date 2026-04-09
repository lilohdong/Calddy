import '../entities/app_user.dart';

/// 인증 기능을 담당하는 리포지토리 인터페이스
abstract class AuthRepository {
  /// 구글 계정을 이용한 로그인
  Future<void> signInWithGoogle();

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

  /// 닉네임 저장 및 온보딩 완료 처리
  Future<void> completeOnboarding({required String nickname});

  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email);

  /// 로그아웃
  Future<void> signOut();

  /// 세션 상태 변화 감지 스트림
  Stream<AppUser?> get authStateChanges;
}
