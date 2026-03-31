import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/app_user_model.dart';

/// AuthRepository 인터페이스의 구체적인 구현체
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SupabaseClient _supabase;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SupabaseClient supabase,
  })  : _remoteDataSource = remoteDataSource,
        _supabase = supabase;

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      final response = await _remoteDataSource.signInWithGoogle();
      final user = response.user;
      if (user != null) {
        return _getAppUserWithProfile(user);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        return _getAppUserWithProfile(user);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        return _getAppUserWithProfile(user);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _remoteDataSource.currentUser;
    if (user != null) {
      return _getAppUserWithProfile(user);
    }
    return null;
  }

  /// auth.users와 profiles 데이터를 결합하여 AppUser 반환
  Future<AppUser> _getAppUserWithProfile(User user) async {
    final profileData = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return AppUserModel.fromSupabase(user, profileData);
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _remoteDataSource.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user != null) {
        return _getAppUserWithProfile(user);
      }
      return null;
    });
  }
}
