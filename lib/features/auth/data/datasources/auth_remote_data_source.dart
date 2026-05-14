import '../../domain/entities/user_entity.dart';

/// 외부 인증 서비스(Supabase, Google)와 직접 통신하는 데이터 소스 인터페이스
///
/// 반환 타입은 모두 도메인 타입(UserEntity) 또는 표준 Dart 타입만 사용한다.
/// Supabase 전용 타입(AuthResponse, User 등)은 구현체(impl)에만 노출된다.
abstract class AuthRemoteDataSource {
  /// 구글 로그인 수행.
  /// 웹: Supabase OAuth 리다이렉트, 모바일: google_sign_in idToken 흐름.
  Future<void> signInWithGoogle();

  /// 이메일 회원가입 — 성공 시 UserEntity 반환, 이메일 인증 대기 상태면 null
  Future<UserEntity?> signUpWithEmail({
    required String email,
    required String password,
  });

  /// 이메일 로그인 — 성공 시 UserEntity 반환
  Future<UserEntity?> signInWithEmail({
    required String email,
    required String password,
  });

  /// 로그아웃 수행
  Future<void> signOut();

  /// 계정 삭제 (Edge Function 경유)
  Future<void> deleteAccount();

  /// profiles 테이블에서 사용자 프로필 조회
  Future<Map<String, dynamic>?> getUserProfile(String userId);

  /// 닉네임 저장 및 온보딩 완료 처리 (이용약관 동의 포함)
  Future<void> completeOnboarding({
    required String nickname,
    required DateTime termsAgreedAt,
    required String termsVersion,
  });

  /// 회원가입 인증 이메일 재발송 (signUp 시 첫 발송은 Supabase 자동 처리)
  Future<void> sendOtp(String email);

  /// OTP 인증번호 검증
  Future<void> verifyOtp({required String email, required String token});

  /// 비밀번호 재설정 이메일 전송
  Future<void> sendPasswordResetEmail(String email);

  /// 세션 갱신 (authStateChanges 재트리거용)
  Future<void> refreshSession();

  /// 현재 세션의 유저 정보 반환 (동기, 프로필 없는 기본 정보만)
  UserEntity? get currentUser;

  /// 인증 상태 변화를 감지하는 스트림 (도메인 타입으로 변환하여 방출)
  Stream<UserEntity?> get onAuthStateChange;
}
