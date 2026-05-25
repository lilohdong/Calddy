import '../../domain/entities/free_slot_entity.dart';
import '../../domain/entities/friend_calendar_event_entity.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/entities/searched_user_entity.dart';

abstract class FriendRemoteDataSource {
  Future<List<SearchedUserEntity>> searchUsers(String query);
  Future<void> sendFriendRequest(String addresseeId);
  Future<void> acceptFriendRequest(String requestId);
  Future<void> rejectFriendRequest(String requestId);
  Future<void> cancelFriendRequest(String requestId);
  Future<List<FriendEntity>> getFriends(FriendSortType sortType);
  Future<void> deleteFriend(String friendId);
  Future<List<FriendRequestEntity>> getIncomingRequests();

  Future<List<FriendCalendarEventEntity>> getFriendCalendar({
    required String friendId,
    required DateTime from,
    required DateTime to,
  });

  /// Supabase RPC: free_slots(p_user1_id, p_user2_id, p_from, p_to)
  /// 단일 친구와의 빈 시간 조회 (mergeCalendars 내부에서 사용)
  Future<List<FreeSlotEntity>> getFreeSlots({
    required String friendId,
    required DateTime from,
    required DateTime to,
  });
}
