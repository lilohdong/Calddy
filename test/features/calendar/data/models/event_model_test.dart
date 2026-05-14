import 'package:calddy/features/calendar/data/models/event_model.dart';
import 'package:calddy/features/calendar/domain/entities/event_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tJson = <String, dynamic>{
    'id': 'event-uuid-1',
    'user_id': 'user-uuid-1',
    'title': '팀 회의',
    'location': '강남역 스타벅스',
    'location_lat': 37.498095,
    'location_lng': 127.027610,
    'start_at': '2026-05-07T10:00:00+09:00',
    'end_at': '2026-05-07T11:00:00+09:00',
    'color': '#FF5733',
    'is_dday': false,
    'memo': '안건 준비',
    'notify_before_min': 15,
    'status': 'pending',
    'appointment_id': null,
    'visibility': 'public',
    'created_at': '2026-05-01T09:00:00+09:00',
  };

  group('EventModel.fromJson', () {
    test('JSON을 올바르게 파싱한다', () {
      final model = EventModel.fromJson(tJson);

      expect(model.id, 'event-uuid-1');
      expect(model.userId, 'user-uuid-1');
      expect(model.title, '팀 회의');
      expect(model.location, '강남역 스타벅스');
      expect(model.locationLat, 37.498095);
      expect(model.color, '#FF5733');
      expect(model.isDday, false);
      expect(model.status, EventStatus.pending);
      expect(model.visibility, EventVisibility.public);
      expect(model.appointmentId, isNull);
      expect(model.notifyBeforeMin, 15);
    });

    test('nullable 필드가 null인 JSON을 파싱한다', () {
      final minimalJson = <String, dynamic>{
        ...tJson,
        'location': null,
        'location_lat': null,
        'location_lng': null,
        'memo': null,
        'notify_before_min': null,
        'appointment_id': null,
      };

      final model = EventModel.fromJson(minimalJson);

      expect(model.location, isNull);
      expect(model.locationLat, isNull);
      expect(model.memo, isNull);
    });
  });

  group('EventModel.toJson', () {
    test('EventModel을 Supabase INSERT용 JSON으로 변환한다 (id 미포함)', () {
      final model = EventModel.fromJson(tJson);
      final json = model.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json['user_id'], 'user-uuid-1');
      expect(json['title'], '팀 회의');
      expect(json['color'], '#FF5733');
      expect(json['status'], 'pending');
      expect(json['visibility'], 'public');
    });
  });

  group('EventModel.fromEntity', () {
    test('EventEntity를 EventModel로 변환한다', () {
      final entity = EventEntity(
        id: 'event-1',
        userId: 'user-1',
        title: '테스트',
        startAt: DateTime(2026, 5, 7, 10),
        endAt: DateTime(2026, 5, 7, 11),
        color: '#4A90D9',
        isDday: false,
        status: EventStatus.pending,
        visibility: EventVisibility.public,
        createdAt: DateTime(2026, 5, 1),
      );

      final model = EventModel.fromEntity(entity);

      expect(model.id, 'event-1');
      expect(model.title, '테스트');
      expect(model, isA<EventModel>());
    });
  });
}
