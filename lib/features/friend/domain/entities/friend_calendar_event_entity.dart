/// 친구의 공개 일정 (calendar 도메인 구현 전 friend 전용 경량 엔티티)
class FriendCalendarEventEntity {
  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String color; // hex (#RRGGBB)

  const FriendCalendarEventEntity({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.color,
  });
}
