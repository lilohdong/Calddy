import 'package:calddy/core/constants/supabase_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/drawing_model.dart';
import 'drawing_remote_datasource.dart';

class DrawingRemoteDataSourceImpl implements DrawingRemoteDataSource {
  final SupabaseClient _client;
  DrawingRemoteDataSourceImpl(this._client);

  @override
  Future<DrawingModel> saveDrawing(DrawingModel drawing) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('session_expired');

    final row = await _client
        .from(SupabaseConstants.drawings)
        .upsert(drawing.toJson(), onConflict: 'user_id,draw_date')
        .select()
        .single();
    return DrawingModel.fromJson(row);
  }

  @override
  Future<DrawingModel?> getDrawingByDate(DateTime date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('session_expired');

    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final row = await _client
        .from(SupabaseConstants.drawings)
        .select()
        .eq('user_id', userId)
        .eq('draw_date', dateStr)
        .maybeSingle();

    return row == null ? null : DrawingModel.fromJson(row);
  }
}
