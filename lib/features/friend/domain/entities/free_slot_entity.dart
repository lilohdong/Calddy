/// 두 유저가 모두 비어 있는 시간대
class FreeSlotEntity {
  final DateTime startAt;
  final DateTime endAt;

  const FreeSlotEntity({required this.startAt, required this.endAt});
}
