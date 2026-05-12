import '../entities/free_slot_entity.dart';
import '../entities/friend_calendar_event_entity.dart';
import '../entities/friend_entity.dart';
import '../entities/searched_user_entity.dart';

abstract class FriendRepository {
  /// 닉네임 기반 유저 검색 (본인 제외, 관계 상태 포함)
  Future<List<SearchedUserEntity>> searchUsers(String query);

  /// 친구 요청 전송
  Future<void> sendFriendRequest(String addresseeId);

  /// 친구 요청 수락 (DB 트리거가 friends 양방향 INSERT 처리)
  Future<void> acceptFriendRequest(String requestId);

  /// 친구 요청 거절
  Future<void> rejectFriendRequest(String requestId);

  /// 친구 요청 취소 (내가 보낸 요청 삭제)
  Future<void> cancelFriendRequest(String requestId);

  /// 내 친구 목록 조회 (가나다순)
  Future<List<FriendEntity>> getFriends();

  /// 친구 삭제 (friends 테이블 양방향 레코드 DELETE)
  Future<void> deleteFriend(String friendId);

  /// 받은 친구 요청 목록 (pending 상태만)
  Future<List<FriendRequestEntity>> getIncomingRequests();

  // ── P2 ────────────────────────────────────────────────────────────────────

  /// 친구의 공개 일정 조회 (비공개 마스킹은 RLS/쿼리에서 처리)
  Future<List<FriendCalendarEventEntity>> getFriendCalendar({
    required String friendId,
    required DateTime from,
    required DateTime to,
  });

  /// 두 유저의 빈 시간대 교차 계산 (Supabase RPC: free_slots)
  Future<List<FreeSlotEntity>> mergeCalendars({
    required String friendId,
    required DateTime from,
    required DateTime to,
  });

  /// 오늘 기준 가장 가까운 공동 빈 시간대 1개 반환
  Future<FreeSlotEntity?> suggestAppointment(String friendId);
}
