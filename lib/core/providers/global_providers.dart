import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 클라이언트 프로바이더
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// 구글 로그인 객체 프로바이더
/// serverClientId: Supabase Google OAuth에 등록한 Web Client ID (idToken 발급에 필수)
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  return GoogleSignIn(
    serverClientId: webClientId.isNotEmpty ? webClientId : null,
  );
});
