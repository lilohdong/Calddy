import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/appointment/data/datasources/appointment_remote_datasource.dart';
import 'package:calddy/features/appointment/data/models/appointment_model.dart';
import 'package:calddy/features/appointment/data/models/invite_model.dart';
import 'package:calddy/features/appointment/data/repositories/appointment_repository_impl.dart';
import 'package:calddy/features/appointment/domain/entities/invite_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAppointmentRemoteDataSource extends Mock
    implements AppointmentRemoteDataSource {}

class FakeAppointmentModel extends Fake implements AppointmentModel {}

AppointmentModel _dummyAppointment({String id = 'appt-1'}) => AppointmentModel(
      id: id,
      eventId: 'event-1',
      creatorId: 'user-1',
      invites: const [],
      createdAt: DateTime(2026, 5, 13),
    );

InviteModel _dummyInvite({String id = 'invite-1'}) => InviteModel(
      id: id,
      appointmentId: 'appt-1',
      inviteeId: 'user-2',
      status: InviteStatus.pending,
      updatedAt: DateTime(2026, 5, 13),
    );

void main() {
  late AppointmentRepositoryImpl repository;
  late MockAppointmentRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAppointmentRemoteDataSource();
    repository =
        AppointmentRepositoryImpl(remoteDataSource: mockDataSource);
  });

  // ── createAppointment ────────────────────────────────────────────────────

  group('createAppointment', () {
    test('DataSource.createAppointment을 호출하고 AppointmentEntity를 반환한다', () async {
      final model = _dummyAppointment();
      when(() => mockDataSource.createAppointment(
            eventId: 'event-1',
            inviteeIds: ['user-2'],
            suggestedPlace: null,
          )).thenAnswer((_) async => model);

      final result = await repository.createAppointment(
        eventId: 'event-1',
        inviteeIds: ['user-2'],
      );

      expect(result.id, 'appt-1');
      expect(result.eventId, 'event-1');
      verify(() => mockDataSource.createAppointment(
            eventId: 'event-1',
            inviteeIds: ['user-2'],
            suggestedPlace: null,
          )).called(1);
    });
  });

  // ── getAppointment ───────────────────────────────────────────────────────

  group('getAppointment', () {
    test('DataSource.getAppointment을 호출하고 AppointmentEntity를 반환한다', () async {
      final model = _dummyAppointment();
      when(() => mockDataSource.getAppointment('appt-1'))
          .thenAnswer((_) async => model);

      final result = await repository.getAppointment('appt-1');

      expect(result.id, 'appt-1');
      verify(() => mockDataSource.getAppointment('appt-1')).called(1);
    });
  });

  // ── getMyInvites ─────────────────────────────────────────────────────────

  group('getMyInvites', () {
    test('DataSource.getMyInvites를 호출하고 List<InviteEntity>를 반환한다', () async {
      when(() => mockDataSource.getMyInvites())
          .thenAnswer((_) async => [_dummyInvite()]);

      final result = await repository.getMyInvites();

      expect(result.length, 1);
      expect(result.first.inviteeId, 'user-2');
      verify(() => mockDataSource.getMyInvites()).called(1);
    });
  });

  // ── acceptInvite ─────────────────────────────────────────────────────────

  group('acceptInvite', () {
    test('DataSource.acceptInvite을 1회 호출한다', () async {
      when(() => mockDataSource.acceptInvite('invite-1'))
          .thenAnswer((_) async {});

      await repository.acceptInvite('invite-1');

      verify(() => mockDataSource.acceptInvite('invite-1')).called(1);
    });
  });

  // ── rejectInvite ─────────────────────────────────────────────────────────

  group('rejectInvite', () {
    test('DataSource.rejectInvite을 1회 호출한다', () async {
      when(() => mockDataSource.rejectInvite('invite-1'))
          .thenAnswer((_) async {});

      await repository.rejectInvite('invite-1');

      verify(() => mockDataSource.rejectInvite('invite-1')).called(1);
    });
  });

  // ── cancelAppointment ────────────────────────────────────────────────────

  group('cancelAppointment', () {
    test('DataSource.cancelAppointment을 1회 호출한다', () async {
      when(() => mockDataSource.cancelAppointment('appt-1'))
          .thenAnswer((_) async {});

      await repository.cancelAppointment('appt-1');

      verify(() => mockDataSource.cancelAppointment('appt-1')).called(1);
    });
  });

  // ── getPlaceSuggestion ───────────────────────────────────────────────────

  group('getPlaceSuggestion', () {
    test('장소가 있으면 String을 반환한다', () async {
      when(() => mockDataSource.getPlaceSuggestion('appt-1'))
          .thenAnswer((_) async => '스타벅스 강남점');

      final result = await repository.getPlaceSuggestion('appt-1');

      expect(result, '스타벅스 강남점');
    });

    test('장소가 없으면 null을 반환한다', () async {
      when(() => mockDataSource.getPlaceSuggestion('appt-1'))
          .thenAnswer((_) async => null);

      final result = await repository.getPlaceSuggestion('appt-1');

      expect(result, isNull);
    });
  });

  // ── requestPlaceSuggestion ───────────────────────────────────────────────

  group('requestPlaceSuggestion', () {
    test('장소 추천 결과를 반환한다', () async {
      when(() => mockDataSource.requestPlaceSuggestion('appt-1'))
          .thenAnswer((_) async => '스타벅스 강남점');

      final result = await repository.requestPlaceSuggestion('appt-1');

      expect(result, '스타벅스 강남점');
      verify(() => mockDataSource.requestPlaceSuggestion('appt-1')).called(1);
    });

    test('추천 결과가 없으면 null을 반환한다', () async {
      when(() => mockDataSource.requestPlaceSuggestion('appt-1'))
          .thenAnswer((_) async => null);

      final result = await repository.requestPlaceSuggestion('appt-1');

      expect(result, isNull);
    });
  });

  // ── _guard: Failure 변환 ─────────────────────────────────────────────────

  group('_guard Failure 매핑', () {
    test('AuthException → AppointmentSessionExpiredFailure', () {
      when(() => mockDataSource.getAppointment(any()))
          .thenThrow(const AuthException('session_expired'));

      expect(
        () => repository.getAppointment('appt-1'),
        throwsA(isA<AppointmentSessionExpiredFailure>()),
      );
    });

    test('PostgrestException code PGRST116 → AppointmentNotFoundFailure', () {
      when(() => mockDataSource.getAppointment(any())).thenThrow(
        const PostgrestException(message: 'no rows', code: 'PGRST116'),
      );

      expect(
        () => repository.getAppointment('appt-1'),
        throwsA(isA<AppointmentNotFoundFailure>()),
      );
    });

    test('PostgrestException 기타 코드 → AppointmentDatabaseFailure', () {
      when(() => mockDataSource.getAppointment(any())).thenThrow(
        const PostgrestException(message: 'RLS violation', code: '42501'),
      );

      expect(
        () => repository.getAppointment('appt-1'),
        throwsA(isA<AppointmentDatabaseFailure>()),
      );
    });

    test('알 수 없는 예외 → AppointmentUnknownFailure', () {
      when(() => mockDataSource.getAppointment(any()))
          .thenThrow(Exception('unexpected'));

      expect(
        () => repository.getAppointment('appt-1'),
        throwsA(isA<AppointmentUnknownFailure>()),
      );
    });
  });
}
