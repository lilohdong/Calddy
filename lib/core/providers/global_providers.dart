import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 클라이언트 프로바이더
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// 구글 로그인 객체 프로바이더
/// serverClientId: Supabase Google OAuth에 등록한 Web Client ID (idToken 발급에 필수)
///
/// GOOGLE_WEB_CLIENT_ID 미설정 시 null을 반환한다.
/// 앱 시작 체인(authStateProvider)이 이 Provider를 watch하므로,
/// 여기서 throw하면 앱 전체가 크래시된다.
/// 에러는 실제로 signInWithGoogle()을 호출하는 시점에 [GoogleConfigMissingFailure]로 처리한다.
final googleSignInProvider = Provider<GoogleSignIn?>((ref) {
  if (kIsWeb) return null; // 웹은 Supabase OAuth 리다이렉트 방식 사용
  const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  if (webClientId.isEmpty) return null;
  return GoogleSignIn(serverClientId: webClientId);
});
