import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../domain/entities/free_slot_entity.dart';
import '../../domain/entities/friend_calendar_event_entity.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/entities/searched_user_entity.dart';
import '../models/free_slot_model.dart';
import '../models/friend_calendar_event_model.dart';
import '../models/friend_model.dart';
import '../models/searched_user_model.dart';
import 'friend_remote_datasource.dart';

class FriendRemoteDataSourceImpl implements FriendRemoteDataSource {
  final SupabaseClient _supabase;

  FriendRemoteDataSourceImpl({required SupabaseClient supabase})
      : _supabase = supabase;

  String get _currentUserId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw const AuthException('session_expired');
    return id;
  }

  @override
  Future<List<SearchedUserEntity>> searchUsers(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final currentUserId = _currentUserId;

    // 1. 닉네임 ILIKE 검색 (본인 제외)
    final profileResults = await _supabase
        .from(SupabaseConstants.profiles)
        .select('id, nickname, avatar_url, bio')
        .ilike('nickname', '%$trimmed%')
        .neq('id', currentUserId)
        .limit(20);

    if ((profileResults as List).isEmpty) return [];

    final resultIds =
        profileResults.map((p) => p['id'] as String).toList();

    // 2. 이미 친구인 ID 조회
    final friendsResult = await _supabase
        .from(SupabaseConstants.friends)
        .select('friend_id')
        .eq('user_id', currentUserId)
        .inFilter('friend_id', resultIds);

    final friendIds = {
      for (final f in (friendsResult as List)) f['friend_id'] as String,
    };

    // 3. 내가 보낸 pending 요청 조회 (검색 결과 대상으로만)
    final sentResult = await _supabase
        .from(SupabaseConstants.friendRequests)
        .select('id, addressee_id')
        .eq('requester_id', currentUserId)
        .eq('status', 'pending')
        .inFilter('addressee_id', resultIds);

    final sentMap = {
      for (final r in (sentResult as List))
        r['addressee_id'] as String: r['id'] as String,
    };

    // 4. 나에게 온 pending 요청 조회 (검색 결과 대상으로만)
    final receivedResult = await _supabase
        .from(SupabaseConstants.friendRequests)
        .select('id, requester_id')
        .eq('addressee_id', currentUserId)
        .eq('status', 'pending')
        .inFilter('requester_id', resultIds);

    final receivedMap = {
      for (final r in (receivedResult as List))
        r['requester_id'] as String: r['id'] as String,
    };

    return profileResults.map((p) {
      final id = p['id'] as String;
      final FriendRelationStatus status;
      String? pendingRequestId;

      if (friendIds.contains(id)) {
        status = FriendRelationStatus.friend;
      } else if (sentMap.containsKey(id)) {
        status = FriendRelationStatus.requestSent;
        pendingRequestId = sentMap[id];
      } else if (receivedMap.containsKey(id)) {
        status = FriendRelationStatus.requestReceived;
        pendingRequestId = receivedMap[id];
      } else {
        status = FriendRelationStatus.none;
      }

      return SearchedUserModel.fromJson(
        p,
        relationStatus: status,
        pendingRequestId: pendingRequestId,
      );
    }).toList();
  }

  @override
  Future<void> sendFriendRequest(String addresseeId) async {
    await _supabase.from(SupabaseConstants.friendRequests).insert({
      'requester_id': _currentUserId,
      'addressee_id': addresseeId,
      'status': 'pending',
    });
  }

  @override
  Future<void> cancelFriendRequest(String requestId) async {
    await _supabase
        .from(SupabaseConstants.friendRequests)
        .delete()
        .eq('id', requestId)
        .eq('requester_id', _currentUserId);
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    // DB 트리거가 friends 테이블 양방향 INSERT를 처리
    await _supabase
        .from(SupabaseConstants.friendRequests)
        .update({'status': 'accepted'})
        .eq('id', requestId)
        .eq('addressee_id', _currentUserId); // RLS 보조: 나에게 온 요청만
  }

  @override
  Future<void> rejectFriendRequest(String requestId) async {
    await _supabase
        .from(SupabaseConstants.friendRequests)
        .update({'status': 'rejected'})
        .eq('id', requestId)
        .eq('addressee_id', _currentUserId);
  }

  @override
  Future<List<FriendEntity>> getFriends(FriendSortType sortType) async {
    final currentUserId = _currentUserId;

    final results = await _supabase
        .from(SupabaseConstants.friends)
        .select('user_id, friend_id, created_at, profiles!friend_id(id, nickname, avatar_url)')
        .eq('user_id', currentUserId);

    final list = List<Map<String, dynamic>>.from(results as List);

    if (sortType == FriendSortType.alphabetical) {
      list.sort((a, b) {
        final aN = ((a['profiles'] as Map?)?['nickname'] as String?) ?? '';
        final bN = ((b['profiles'] as Map?)?['nickname'] as String?) ?? '';
        return aN.compareTo(bN);
      });
      return list.map((json) => FriendModel.fromJson(json)).toList();
    }

    // freeTimeOverlap: 오늘~+30일 기준 빈 슬롯 수 내림차순
    final now = DateTime.now();
    final to = now.add(const Duration(days: 30));
    final slotCounts = await Future.wait(
      list.map((friend) async {
        final friendId = (friend['profiles'] as Map)['id'] as String;
        try {
          final slots = await getFreeSlots(friendId: friendId, from: now, to: to);
          return slots.length;
        } catch (_) {
          return 0;
        }
      }),
    );

    final indexed = List.generate(list.length, (i) => i);
    indexed.sort((a, b) => slotCounts[b].compareTo(slotCounts[a]));
    return indexed.map((i) => FriendModel.fromJson(list[i])).toList();
  }

  @override
  Future<void> deleteFriend(String friendId) async {
    final currentUserId = _currentUserId;
    // RLS: auth.uid()가 user_id 또는 friend_id인 행 삭제 가능
    await Future.wait([
      _supabase
          .from(SupabaseConstants.friends)
          .delete()
          .eq('user_id', currentUserId)
          .eq('friend_id', friendId),
      _supabase
          .from(SupabaseConstants.friends)
          .delete()
          .eq('user_id', friendId)
          .eq('friend_id', currentUserId),
    ]);
  }

  @override
  Future<List<FriendRequestEntity>> getIncomingRequests() async {
    final results = await _supabase
        .from(SupabaseConstants.friendRequests)
        .select(
          'id, requester_id, created_at, profiles!requester_id(id, nickname, avatar_url)',
        )
        .eq('addressee_id', _currentUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (results as List)
        .map(
          (json) => FriendRequestModel.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  // ── P2 ────────────────────────────────────────────────────────────────────

  @override
  Future<List<FriendCalendarEventEntity>> getFriendCalendar({
    required String friendId,
    required DateTime from,
    required DateTime to,
  }) async {
    // visibility='public' 필터는 RLS 정책으로도 보장되지만 명시적으로 쿼리에 포함
    final results = await _supabase
        .from(SupabaseConstants.events)
        .select('id, title, start_at, end_at, color')
        .eq('user_id', friendId)
        .eq('visibility', 'public')
        .lte('start_at', to.toIso8601String())
        .gte('end_at', from.toIso8601String())
        .order('start_at');

    return (results as List)
        .map((json) => FriendCalendarEventModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FreeSlotEntity>> getFreeSlots({
    required String friendId,
    required DateTime from,
    required DateTime to,
  }) async {
    final result = await _supabase.rpc('free_slots', params: {
      'p_user1_id': _currentUserId,
      'p_user2_id': friendId,
      'p_from': from.toIso8601String(),
      'p_to': to.toIso8601String(),
    });

    return (result as List)
        .map((json) => FreeSlotModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

}
