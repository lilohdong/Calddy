import 'dart:typed_data';

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

  @override
  Future<String> uploadThumbnail(Uint8List bytes, String date) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('session_expired');

    final fileName = 'drawing_${userId}_$date.png';
    await _client.storage
        .from(SupabaseConstants.drawingsBucket)
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
        );
    return _client.storage
        .from(SupabaseConstants.drawingsBucket)
        .getPublicUrl(fileName);
  }

  @override
  Future<Map<String, String?>> getDrawingThumbnailsForMonth(
      int year, int month) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('session_expired');

    final lastDay = DateTime(year, month + 1, 0).day;
    final startStr =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final endStr =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';

    final rows = await _client
        .from(SupabaseConstants.drawings)
        .select('draw_date, thumbnail_url')
        .eq('user_id', userId)
        .gte('draw_date', startStr)
        .lte('draw_date', endStr);

    return {
      for (final row in rows as List<dynamic>)
        (row as Map<String, dynamic>)['draw_date'] as String:
            row['thumbnail_url'] as String?,
    };
  }
}
