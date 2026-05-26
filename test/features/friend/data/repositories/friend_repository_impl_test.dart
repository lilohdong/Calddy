import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/auth/domain/entities/user_entity.dart';
import 'package:calddy/features/friend/data/datasources/friend_remote_datasource.dart';
import 'package:calddy/features/friend/data/repositories/friend_repository_impl.dart';
import 'package:calddy/features/friend/domain/entities/free_slot_entity.dart';
import 'package:calddy/features/friend/domain/entities/friend_calendar_event_entity.dart';
import 'package:calddy/features/friend/domain/entities/friend_entity.dart';
import 'package:calddy/features/friend/domain/entities/searched_user_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockFriendRemoteDataSource extends Mock
    implements FriendRemoteDataSource {}

// ── 공통 테스트 데이터 ─────────────────────────────────────────────────────────

final _tUserProfile = UserEntity(
  id: 'user-001',
  email: 'user@test.com',
  nickname: '테스트유저',
);

final _tFriendEntity = FriendEntity(
  userId: 'me-001',
  friendId: 'user-001',
  friendProfile: _tUserProfile,
  status: FriendRequestStatus.accepted,
  createdAt: DateTime(2026, 5, 1),
);

final _tFriendRequestEntity = FriendRequestEntity(
  id: 'req-001',
  requesterId: 'user-001',
  requesterProfile: _tUserProfile,
  createdAt: DateTime(2026, 5, 1),
);

final _tSearchedUser = SearchedUserEntity(
  id: 'user-001',
  nickname: '검색결과유저',
  relationStatus: FriendRelationStatus.none,
);

final _tCalendarEvent = FriendCalendarEventEntity(
  id: 'event-001',
  title: '친구 일정',
  startAt: DateTime(2026, 6, 10, 10),
  endAt: DateTime(2026, 6, 10, 12),
  color: '#FF5733',
);

// ── main ──────────────────────────────────────────────────────────────────────

void main() {
  late FriendRepositoryImpl repository;
  late MockFriendRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockFriendRemoteDataSource();
    repository =
        FriendRepositoryImpl(remoteDataSource: mockDataSource);
    registerFallbackValue(FriendSortType.alphabetical);
    registerFallbackValue(DateTime(2026));
  });

  // ── searchUsers ────────────────────────────────────────────────────────────
  group('searchUsers', () {
    test('성공 시 SearchedUserEntity 목록을 반환한다', () async {
      when(() => mockDataSource.searchUsers(any()))
          .thenAnswer((_) async => [_tSearchedUser]);

      final result = await repository.searchUsers('검색');

      expect(result, [_tSearchedUser]);
    });

    test('PostgrestException 발생 시 UnknownFriendFailure를 throw한다', () {
      when(() => mockDataSource.searchUsers(any()))
          .thenThrow(PostgrestException(message: 'db error', code: '42P01'));

      expect(
        () => repository.searchUsers('검색'),
        throwsA(isA<UnknownFriendFailure>()),
      );
    });

    test('AuthException 발생 시 그대로 rethrow한다', () {
      when(() => mockDataSource.searchUsers(any()))
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.searchUsers('검색'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  // ── sendFriendRequest ──────────────────────────────────────────────────────
  group('sendFriendRequest', () {
    test('성공 시 예외 없이 완료된다', () async {
      when(() => mockDataSource.sendFriendRequest(any()))
          .thenAnswer((_) async {});

      await expectLater(
          repository.sendFriendRequest('user-001'), completes);
    });

    test('UNIQUE 위반(23505) 시 FriendRequestAlreadySentFailure를 throw한다', () {
      when(() => mockDataSource.sendFriendRequest(any()))
          .thenThrow(
              PostgrestException(message: 'duplicate key', code: '23505'));

      expect(
        () => repository.sendFriendRequest('user-001'),
        throwsA(isA<FriendRequestAlreadySentFailure>()),
      );
    });

    test('기타 PostgrestException 시 UnknownFriendFailure를 throw한다', () {
      when(() => mockDataSource.sendFriendRequest(any()))
          .thenThrow(
              PostgrestException(message: 'server error', code: '500'));

      expect(
        () => repository.sendFriendRequest('user-001'),
        throwsA(isA<UnknownFriendFailure>()),
      );
    });

    test('AuthException 발생 시 그대로 rethrow한다', () {
      when(() => mockDataSource.sendFriendRequest(any()))
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.sendFriendRequest('user-001'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  // ── cancelFriendRequest ────────────────────────────────────────────────────
  group('cancelFriendRequest', () {
    test('성공 시 예외 없이 완료된다', () async {
      when(() => mockDataSource.cancelFriendRequest(any()))
          .thenAnswer((_) async {});

      await expectLater(
          repository.cancelFriendRequest('req-001'), completes);
    });

    test('PostgrestException 발생 시 UnknownFriendFailure를 throw한다', () {
      when(() => mockDataSource.cancelFriendRequest(any()))
          .thenThrow(PostgrestException(message: 'error', code: '42P01'));

      expect(
        () => repository.cancelFriendRequest('req-001'),
        throwsA(isA<UnknownFriendFailure>()),
      );
    });

    test('AuthException 발생 시 그대로 rethrow한다', () {
      when(() => mockDataSource.cancelFriendRequest(any()))
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.cancelFriendRequest('req-001'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  // ── acceptFriendRequest ────────────────────────────────────────────────────
  group('acceptFriendRequest', () {
    test('성공 시 예외 없이 완료된다', () async {
      when(() => mockDataSource.acceptFriendRequest(any()))
          .thenAnswer((_) async {});

      await expectLater(
          repository.acceptFriendRequest('req-001'), completes);
    });

    test('PostgrestException 발생 시 UnknownFriendFailure를 throw한다', () {
      when(() => mockDataSource.acceptFriendRequest(any()))
          .thenThrow(PostgrestException(message: 'error', code: '42P01'));

      expect(
        () => repository.acceptFriendRequest('req-001'),
        throwsA(isA<UnknownFriendFailure>()),
      );
    });
  });

  // ── rejectFriendRequest ────────────────────────────────────────────────────
  group('rejectFriendRequest', () {
    test('성공 시 예외 없이 완료된다', () async {
      when(() => mockDataSource.rejectFriendRequest(any()))
          .thenAnswer((_) async {});

      await expectLater(
          repository.rejectFriendRequest('req-001'), completes);
    });

    test('PostgrestException 발생 시 UnknownFriendFailure를 throw한다', () {
      when(() => mockDataSource.rejectFriendRequest(any()))
          .thenThrow(PostgrestException(message: 'error', code: '42P01'));

      expect(
        () => repository.rejectFriendRequest('req-001'),
        throwsA(isA<UnknownFriendFailure>()),
      );
    });
  });

  // ── getFriends ─────────────────────────────────────────────────────────────
  group('getFriends', () {
    test('성공 시 FriendEntity 목록을 반환한다', () async {
      when(() => mockDataSource.getFriends(any()))
          .thenAnswer((_) async => [_tFriendEntity]);

      final result =
          await repository.getFriends(FriendSortType.alphabetical);

      expect(result, [_tFriendEntity]);
    });

    test('PostgrestException 발생 시 UnknownFriendFailure를 throw한다', () {
      when(() => mockDataSource.getFriends(any()))
          .thenThrow(PostgrestException(message: 'error', code: '42P01'));

      expect(
        () => repository.getFriends(FriendSortType.alphabetical),
        throwsA(isA<UnknownFriendFailure>()),
      );
    });

    test('AuthException 발생 시 그대로 rethrow한다', () {
      when(() => mockDataSource.getFriends(any()))
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.getFriends(FriendSortType.alphabetical),
        throwsA(isA<AuthException>()),
      );
    });
  });

  // ── deleteFriend ───────────────────────────────────────────────────────────
  group('deleteFriend', () {
    test('성공 시 예외 없이 완료된다', () async {
      when(() => mockDataSource.deleteFriend(any()))
          .thenAnswer((_) async {});

      await expectLater(repository.deleteFriend('user-001'), completes);
    });

    test('PostgrestException 발생 시 UnknownFriendFailure를 throw한다', () {
      when(() => mockDataSource.deleteFriend(any()))
          .thenThrow(PostgrestException(message: 'error', code: '42P01'));

      expect(
        () => repository.deleteFriend('user-001'),
        throwsA(isA<UnknownFriendFailure>()),
      );
    });
  });

  // ── getIncomingRequests ────────────────────────────────────────────────────
  group('getIncomingRequests', () {
    test('성공 시 FriendRequestEntity 목록을 반환한다', () async {
      when(() => mockDataSource.getIncomingRequests())
          .thenAnswer((_) async => [_tFriendRequestEntity]);

      final result = await repository.getIncomingRequests();

      expect(result, [_tFriendRequestEntity]);
    });

    test('요청이 없으면 빈 리스트를 반환한다', () async {
      when(() => mockDataSource.getIncomingRequests())
          .thenAnswer((_) async => []);

      final result = await repository.getIncomingRequests();

      expect(result, isEmpty);
    });

    test('PostgrestException 발생 시 UnknownFriendFailure를 throw한다', () {
      when(() => mockDataSource.getIncomingRequests())
          .thenThrow(PostgrestException(message: 'error', code: '42P01'));

      expect(
        () => repository.getIncomingRequests(),
        throwsA(isA<UnknownFriendFailure>()),
      );
    });
  });

  // ── getFriendCalendar ──────────────────────────────────────────────────────
  group('getFriendCalendar', () {
    final tFrom = DateTime(2026, 6, 1);
    final tTo = DateTime(2026, 6, 30);

    test('성공 시 FriendCalendarEventEntity 목록을 반환한다', () async {
      when(() => mockDataSource.getFriendCalendar(
            friendId: any(named: 'friendId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => [_tCalendarEvent]);

      final result = await repository.getFriendCalendar(
        friendId: 'user-001',
        from: tFrom,
        to: tTo,
      );

      expect(result, [_tCalendarEvent]);
    });

    test('PostgrestException 발생 시 UnknownFriendFailure를 throw한다', () {
      when(() => mockDataSource.getFriendCalendar(
            friendId: any(named: 'friendId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenThrow(
              PostgrestException(message: 'error', code: '42P01'));

      expect(
        () => repository.getFriendCalendar(
          friendId: 'user-001',
          from: tFrom,
          to: tTo,
        ),
        throwsA(isA<UnknownFriendFailure>()),
      );
    });
  });

  // ── mergeCalendars / _intersectSlots ───────────────────────────────────────
  group('mergeCalendars', () {
    final tFrom = DateTime(2026, 6, 1);
    final tTo = DateTime(2026, 6, 30);

    test('friendIds가 비어있으면 DataSource를 호출하지 않고 빈 리스트를 반환한다', () async {
      final result = await repository.mergeCalendars(
        friendIds: [],
        from: tFrom,
        to: tTo,
      );

      expect(result, isEmpty);
      verifyNever(() => mockDataSource.getFreeSlots(
            friendId: any(named: 'friendId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          ));
    });

    test('친구 1명 — RPC 결과를 그대로 반환한다', () async {
      final tSlots = [
        FreeSlotEntity(
          startAt: DateTime(2026, 6, 10, 9),
          endAt: DateTime(2026, 6, 10, 11),
        ),
      ];
      when(() => mockDataSource.getFreeSlots(
            friendId: any(named: 'friendId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => tSlots);

      final result = await repository.mergeCalendars(
        friendIds: ['user-001'],
        from: tFrom,
        to: tTo,
      );

      expect(result, tSlots);
    });

    test('친구 2명 — 겹치는 시간대만 반환한다 (교집합)', () async {
      // A 빈 시간: 9:00 ~ 12:00
      // B 빈 시간: 10:00 ~ 13:00
      // 교집합: 10:00 ~ 12:00
      final slotsA = [
        FreeSlotEntity(
          startAt: DateTime(2026, 6, 10, 9),
          endAt: DateTime(2026, 6, 10, 12),
        ),
      ];
      final slotsB = [
        FreeSlotEntity(
          startAt: DateTime(2026, 6, 10, 10),
          endAt: DateTime(2026, 6, 10, 13),
        ),
      ];

      var callCount = 0;
      when(() => mockDataSource.getFreeSlots(
            friendId: any(named: 'friendId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? slotsA : slotsB;
      });

      final result = await repository.mergeCalendars(
        friendIds: ['user-001', 'user-002'],
        from: tFrom,
        to: tTo,
      );

      expect(result.length, 1);
      expect(result[0].startAt, DateTime(2026, 6, 10, 10));
      expect(result[0].endAt, DateTime(2026, 6, 10, 12));
    });

    test('친구 2명 — 겹치는 시간이 없으면 빈 리스트를 반환한다', () async {
      // A: 9:00 ~ 10:00, B: 11:00 ~ 12:00 → 교집합 없음
      final slotsA = [
        FreeSlotEntity(
          startAt: DateTime(2026, 6, 10, 9),
          endAt: DateTime(2026, 6, 10, 10),
        ),
      ];
      final slotsB = [
        FreeSlotEntity(
          startAt: DateTime(2026, 6, 10, 11),
          endAt: DateTime(2026, 6, 10, 12),
        ),
      ];

      var callCount = 0;
      when(() => mockDataSource.getFreeSlots(
            friendId: any(named: 'friendId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? slotsA : slotsB;
      });

      final result = await repository.mergeCalendars(
        friendIds: ['user-001', 'user-002'],
        from: tFrom,
        to: tTo,
      );

      expect(result, isEmpty);
    });

    test('PostgrestException 발생 시 UnknownFriendFailure를 throw한다', () {
      when(() => mockDataSource.getFreeSlots(
            friendId: any(named: 'friendId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenThrow(
              PostgrestException(message: 'rpc error', code: '42883'));

      expect(
        () => repository.mergeCalendars(
          friendIds: ['user-001'],
          from: tFrom,
          to: tTo,
        ),
        throwsA(isA<UnknownFriendFailure>()),
      );
    });
  });

  // ── suggestAppointment ─────────────────────────────────────────────────────
  group('suggestAppointment', () {
    test('빈 슬롯이 있으면 첫 번째 슬롯을 반환한다', () async {
      final tSlot = FreeSlotEntity(
        startAt: DateTime(2026, 6, 10, 10),
        endAt: DateTime(2026, 6, 10, 12),
      );
      when(() => mockDataSource.getFreeSlots(
            friendId: any(named: 'friendId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => [tSlot]);

      final result = await repository.suggestAppointment('user-001');

      expect(result, tSlot);
    });

    test('빈 슬롯이 없으면 null을 반환한다', () async {
      when(() => mockDataSource.getFreeSlots(
            friendId: any(named: 'friendId'),
            from: any(named: 'from'),
            to: any(named: 'to'),
          )).thenAnswer((_) async => []);

      final result = await repository.suggestAppointment('user-001');

      expect(result, isNull);
    });
  });
}
