import '../../domain/entities/drawing_entity.dart';

class DrawingModel extends DrawingEntity {
  const DrawingModel({
    required super.id,
    required super.userId,
    required super.drawDate,
    required super.strokes,
    super.thumbnailUrl,
    required super.updatedAt,
  });

  factory DrawingModel.fromJson(Map<String, dynamic> json) => DrawingModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        drawDate: DateTime.parse(json['draw_date'] as String),
        strokes: (json['strokes'] as List<dynamic>)
            .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
            .toList(),
        thumbnailUrl: json['thumbnail_url'] as String?,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  factory DrawingModel.fromEntity(DrawingEntity e) => DrawingModel(
        id: e.id,
        userId: e.userId,
        drawDate: e.drawDate,
        strokes: e.strokes,
        thumbnailUrl: e.thumbnailUrl,
        updatedAt: e.updatedAt,
      );

  // UPSERT payload: id 미포함 (onConflict: user_id,draw_date)
  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'draw_date':
            '${drawDate.year.toString().padLeft(4, '0')}-${drawDate.month.toString().padLeft(2, '0')}-${drawDate.day.toString().padLeft(2, '0')}',
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'thumbnail_url': thumbnailUrl,
        'updated_at': updatedAt.toIso8601String(),
      };
}
