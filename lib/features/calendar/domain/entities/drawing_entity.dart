class DrawingStroke {
  final String color;
  final double width;
  final List<List<double>> points; // [[x, y], [x, y], ...]

  const DrawingStroke({
    required this.color,
    required this.width,
    required this.points,
  });

  factory DrawingStroke.fromJson(Map<String, dynamic> json) => DrawingStroke(
        color: json['color'] as String,
        width: (json['width'] as num).toDouble(),
        points: (json['points'] as List<dynamic>)
            .map((p) => (p as List<dynamic>)
                .map((v) => (v as num).toDouble())
                .toList())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'color': color,
        'width': width,
        'points': points,
      };
}

class DrawingEntity {
  final String id;
  final String userId;
  final DateTime drawDate;
  final List<DrawingStroke> strokes;
  final String? thumbnailUrl;
  final DateTime updatedAt;

  const DrawingEntity({
    required this.id,
    required this.userId,
    required this.drawDate,
    required this.strokes,
    this.thumbnailUrl,
    required this.updatedAt,
  });

  DrawingEntity copyWith({
    String? id,
    String? userId,
    DateTime? drawDate,
    List<DrawingStroke>? strokes,
    String? thumbnailUrl,
    DateTime? updatedAt,
  }) =>
      DrawingEntity(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        drawDate: drawDate ?? this.drawDate,
        strokes: strokes ?? this.strokes,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
