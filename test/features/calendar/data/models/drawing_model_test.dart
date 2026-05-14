import 'package:calddy/features/calendar/data/models/drawing_model.dart';
import 'package:calddy/features/calendar/domain/entities/drawing_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tJson = <String, dynamic>{
    'id': 'drawing-uuid-1',
    'user_id': 'user-uuid-1',
    'draw_date': '2026-05-07',
    'strokes': [
      {
        'color': '#FF0000',
        'width': 3.0,
        'points': [[10.0, 20.0], [15.0, 25.0]],
      },
    ],
    'thumbnail_url': null,
    'updated_at': '2026-05-07T10:00:00+09:00',
  };

  group('DrawingModel.fromJson', () {
    test('JSON을 올바르게 파싱한다', () {
      final model = DrawingModel.fromJson(tJson);

      expect(model.id, 'drawing-uuid-1');
      expect(model.userId, 'user-uuid-1');
      expect(model.drawDate, DateTime(2026, 5, 7));
      expect(model.strokes.length, 1);
      expect(model.strokes.first.color, '#FF0000');
      expect(model.strokes.first.width, 3.0);
      expect(model.strokes.first.points.first, [10.0, 20.0]);
      expect(model.thumbnailUrl, isNull);
    });

    test('strokes가 빈 배열이어도 파싱된다', () {
      final json = {...tJson, 'strokes': <dynamic>[]};
      final model = DrawingModel.fromJson(json);
      expect(model.strokes, isEmpty);
    });
  });

  group('DrawingModel.toJson', () {
    test('toJson에 user_id + draw_date + strokes가 포함된다', () {
      final entity = DrawingEntity(
        id: 'drawing-1',
        userId: 'user-1',
        drawDate: DateTime(2026, 5, 7),
        strokes: [
          DrawingStroke(
              color: '#0000FF', width: 2.0, points: [[1.0, 2.0]]),
        ],
        updatedAt: DateTime(2026, 5, 7, 10),
      );
      final model = DrawingModel.fromEntity(entity);
      final json = model.toJson();

      expect(json['user_id'], 'user-1');
      expect(json['draw_date'], '2026-05-07');
      expect((json['strokes'] as List).length, 1);
      expect(json.containsKey('id'), false);
    });
  });
}
