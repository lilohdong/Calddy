import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/free_slot_entity.dart';
import '../../domain/entities/friend_calendar_event_entity.dart';
import '../../domain/entities/friend_entity.dart';
import '../../domain/entities/searched_user_entity.dart';
import '../../domain/repositories/friend_repository.dart';
import '../datasources/friend_remote_datasource.dart';

class FriendRepositoryImpl implements FriendRepository {
  final FriendRemoteDataSource _remoteDataSource;

  FriendRepositoryImpl({required FriendRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<SearchedUserEntity>> searchUsers(String query) async {
    try {
      return await _remoteDataSource.searchUsers(query);
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const UnknownFriendFailure();
    }
  }

  @override
  Future<void> sendFriendRequest(String addresseeId) async {
    try {
      await _remoteDataSource.sendFriendRequest(addresseeId);
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const FriendRequestAlreadySentFailure();
      throw _mapPostgrest(e);
    } catch (_) {
      throw const UnknownFriendFailure();
    }
  }

  @override
  Future<void> cancelFriendRequest(String requestId) async {
    try {
      await _remoteDataSource.cancelFriendRequest(requestId);
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const UnknownFriendFailure();
    }
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _remoteDataSource.acceptFriendRequest(requestId);
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const UnknownFriendFailure();
    }
  }

  @override
  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _remoteDataSource.rejectFriendRequest(requestId);
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const UnknownFriendFailure();
    }
  }

  @override
  Future<List<FriendEntity>> getFriends(FriendSortType sortType) async {
    try {
      return await _remoteDataSource.getFriends(sortType);
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const UnknownFriendFailure();
    }
  }

  @override
  Future<void> deleteFriend(String friendId) async {
    try {
      await _remoteDataSource.deleteFriend(friendId);
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const UnknownFriendFailure();
    }
  }

  @override
  Future<List<FriendRequestEntity>> getIncomingRequests() async {
    try {
      return await _remoteDataSource.getIncomingRequests();
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const UnknownFriendFailure();
    }
  }

  // ── P2 ────────────────────────────────────────────────────────────────────

  @override
  Future<List<FriendCalendarEventEntity>> getFriendCalendar({
    required String friendId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      return await _remoteDataSource.getFriendCalendar(
        friendId: friendId,
        from: from,
        to: to,
      );
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const UnknownFriendFailure();
    }
  }

  @override
  Future<List<FreeSlotEntity>> mergeCalendars({
    required List<String> friendIds,
    required DateTime from,
    required DateTime to,
  }) async {
    if (friendIds.isEmpty) return [];
    try {
      final allSlots = await Future.wait(
        friendIds.map(
          (id) => _remoteDataSource.getFreeSlots(friendId: id, from: from, to: to),
        ),
      );
      var intersection = allSlots[0];
      for (int i = 1; i < allSlots.length; i++) {
        intersection = _intersectSlots(intersection, allSlots[i]);
        if (intersection.isEmpty) break;
      }
      return intersection;
    } on PostgrestException catch (e) {
      throw _mapPostgrest(e);
    } catch (_) {
      throw const UnknownFriendFailure();
    }
  }

  List<FreeSlotEntity> _intersectSlots(
    List<FreeSlotEntity> a,
    List<FreeSlotEntity> b,
  ) {
    final result = <FreeSlotEntity>[];
    for (final slotA in a) {
      for (final slotB in b) {
        final start = slotA.startAt.isAfter(slotB.startAt) ? slotA.startAt : slotB.startAt;
        final end = slotA.endAt.isBefore(slotB.endAt) ? slotA.endAt : slotB.endAt;
        if (start.isBefore(end)) {
          result.add(FreeSlotEntity(startAt: start, endAt: end));
        }
      }
    }
    return result;
  }

  @override
  Future<FreeSlotEntity?> suggestAppointment(String friendId) async {
    try {
      final now = DateTime.now();
      final slots = await mergeCalendars(
        friendIds: [friendId],
        from: now,
        to: now.add(const Duration(days: 30)),
      );
      return slots.isNotEmpty ? slots.first : null;
    } on FriendFailure {
      rethrow;
    } catch (_) {
      throw const UnknownFriendFailure();
    }
  }

  FriendFailure _mapPostgrest(PostgrestException e) {
    switch (e.code) {
      case '23505':
        return const FriendRequestAlreadySentFailure();
      default:
        return const UnknownFriendFailure();
    }
  }
}
