import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_constants.dart';
import '../../domain/entities/report_entity.dart';
import 'report_remote_datasource.dart';

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final SupabaseClient _supabase;

  ReportRemoteDataSourceImpl({required SupabaseClient supabase})
      : _supabase = supabase;

  String get _currentUserId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const AuthException('session_expired');
    return id;
  }

  @override
  Future<void> report({
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
  }) async {
    await _supabase.from(SupabaseConstants.reports).insert({
      'reporter_id': _currentUserId,
      'target_type': _targetTypeToString(targetType),
      'target_id': targetId,
      'reason': reason,
    });
  }

  String _targetTypeToString(ReportTargetType type) {
    switch (type) {
      case ReportTargetType.post:    return 'post';
      case ReportTargetType.comment: return 'comment';
      case ReportTargetType.user:    return 'user';
    }
  }
}
