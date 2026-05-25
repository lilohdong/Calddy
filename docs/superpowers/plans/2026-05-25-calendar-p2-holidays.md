# Calendar P2 – 공휴일 연동 구현 플랜

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `CalendarData`에 공휴일 목록을 포함시켜 월별/주별 조회 시 자동으로 반환한다.

**Architecture:** `CalendarRemoteDataSourceImpl`에 `getHolidaysByRange` 메서드를 추가하고, `CalendarRepositoryImpl`에서 `Future.wait`로 events와 holidays를 병렬 조회한 뒤 `CalendarData.holidays`에 담는다. UseCase/Provider는 변경 없음.

**Tech Stack:** Dart, Supabase Flutter SDK, Riverpod, flutter_test, mocktail

---

## 수정 파일 맵

| 파일 | 유형 |
|------|------|
| `lib/features/calendar/domain/entities/holiday_entity.dart` | 신규 |
| `lib/features/calendar/data/models/holiday_model.dart` | 신규 |
| `test/features/calendar/data/models/holiday_model_test.dart` | 신규 |
| `lib/features/calendar/domain/entities/calendar_data.dart` | 수정 |
| `lib/features/calendar/data/datasources/calendar_remote_datasource.dart` | 수정 |
| `lib/features/calendar/data/datasources/calendar_remote_datasource_impl.dart` | 수정 |
| `lib/features/calendar/domain/repositories/calendar_repository.dart` | 수정 |
| `lib/features/calendar/data/repositories/calendar_repository_impl.dart` | 수정 |
| `test/features/calendar/data/repositories/calendar_repository_impl_test.dart` | 수정 |

---

## Task 1: 브랜치 생성

**Files:** 없음

- [ ] **Step 1: 브랜치 생성 및 체크아웃**

```bash
git checkout -b feat/calendar_v2
```

Expected: `Switched to a new branch 'feat/calendar_v2'`

---

## Task 2: HolidayEntity 생성

**Files:**
- Create: `lib/features/calendar/domain/entities/holiday_entity.dart`

- [ ] **Step 1: HolidayEntity 파일 작성**

`lib/features/calendar/domain/entities/holiday_entity.dart`:
```dart
class HolidayEntity {
  final DateTime date;
  final String name;

  const HolidayEntity({required this.date, required this.name});
}
```

- [ ] **Step 2: 컴파일 확인**

```bash
dart analyze lib/features/calendar/domain/entities/holiday_entity.dart
```

Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/calendar/domain/entities/holiday_entity.dart
git commit -m "feat: HolidayEntity 도메인 엔티티 추가"
```

---

## Task 3: HolidayModel 생성 (TDD)

**Files:**
- Create: `test/features/calendar/data/models/holiday_model_test.dart`
- Create: `lib/features/calendar/data/models/holiday_model.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/features/calendar/data/models/holiday_model_test.dart`:
```dart
import 'package:calddy/features/calendar/data/models/holiday_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HolidayModel', () {
    final json = {'date': '2026-01-01', 'name': '신정'};

    test('fromJson이 date와 name을 올바르게 파싱한다', () {
      final model = HolidayModel.fromJson(json);
      expect(model.date, DateTime(2026, 1, 1));
      expect(model.name, '신정');
    });

    test('toEntity가 HolidayEntity를 올바르게 반환한다', () {
      final model = HolidayModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity.date, DateTime(2026, 1, 1));
      expect(entity.name, '신정');
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
flutter test test/features/calendar/data/models/holiday_model_test.dart
```

Expected: FAIL — `Target of URI doesn't exist`

- [ ] **Step 3: HolidayModel 구현**

`lib/features/calendar/data/models/holiday_model.dart`:
```dart
import '../../domain/entities/holiday_entity.dart';

class HolidayModel {
  final DateTime date;
  final String name;

  const HolidayModel({required this.date, required this.name});

  factory HolidayModel.fromJson(Map<String, dynamic> json) => HolidayModel(
        date: DateTime.parse(json['date'] as String),
        name: json['name'] as String,
      );

  HolidayEntity toEntity() => HolidayEntity(date: date, name: name);
}
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
flutter test test/features/calendar/data/models/holiday_model_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: 커밋**

```bash
git add lib/features/calendar/data/models/holiday_model.dart \
        test/features/calendar/data/models/holiday_model_test.dart
git commit -m "feat: HolidayModel 추가 + 테스트"
```

---

## Task 4: CalendarData에 holidays 필드 추가

**Files:**
- Modify: `lib/features/calendar/domain/entities/calendar_data.dart`

- [ ] **Step 1: CalendarData 수정**

`lib/features/calendar/domain/entities/calendar_data.dart` 전체 교체:
```dart
import 'event_entity.dart';
import 'holiday_entity.dart';

class CalendarData {
  final List<EventEntity> events;
  final List<EventEntity> habits;
  final List<EventEntity> ranges;
  final List<HolidayEntity> holidays;

  const CalendarData({
    required this.events,
    this.habits = const [],
    this.ranges = const [],
    this.holidays = const [],
  });
}
```

- [ ] **Step 2: 기존 테스트가 여전히 통과하는지 확인**

```bash
flutter test test/features/calendar/
```

Expected: `All tests passed!`
(CalendarData 생성자에 `holidays` 기본값이 있으므로 기존 테스트 수정 불필요)

- [ ] **Step 3: 커밋**

```bash
git add lib/features/calendar/domain/entities/calendar_data.dart
git commit -m "feat: CalendarData에 holidays 필드 추가"
```

---

## Task 5: CalendarRemoteDataSource에 getHolidaysByRange 추가

**Files:**
- Modify: `lib/features/calendar/data/datasources/calendar_remote_datasource.dart`
- Modify: `lib/features/calendar/data/datasources/calendar_remote_datasource_impl.dart`

- [ ] **Step 1: 추상 인터페이스에 메서드 선언**

`lib/features/calendar/data/datasources/calendar_remote_datasource.dart`:
```dart
import '../models/event_model.dart';
import '../models/holiday_model.dart';

abstract interface class CalendarRemoteDataSource {
  Future<List<EventModel>> getEventsByDateRange(DateTime start, DateTime end);
  Future<List<HolidayModel>> getHolidaysByRange(DateTime start, DateTime end);
  Future<EventModel> createEvent(EventModel event);
  Future<List<EventModel>> createEvents(List<EventModel> events);
  Future<EventModel> updateEvent(EventModel event);
  Future<void> deleteEvent(String eventId);
  Future<void> deleteRecurringFrom(String parentOrEventId, DateTime from);
  Future<EventModel> completeEvent(String eventId);
}
```

- [ ] **Step 2: 구현체에 메서드 추가**

`lib/features/calendar/data/datasources/calendar_remote_datasource_impl.dart`의 `completeEvent` 메서드 바로 위에 아래를 삽입:

```dart
  @override
  Future<List<HolidayModel>> getHolidaysByRange(
      DateTime start, DateTime end) async {
    final startStr =
        '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final rows = await _client
        .from(SupabaseConstants.holidays)
        .select('date, name')
        .gte('date', startStr)
        .lte('date', endStr)
        .order('date');
    return rows.map((r) => HolidayModel.fromJson(r)).toList();
  }
```

파일 상단 import에 `HolidayModel` 추가:
```dart
import '../models/holiday_model.dart';
```

- [ ] **Step 3: 컴파일 확인**

```bash
dart analyze lib/features/calendar/data/datasources/
```

Expected: `No issues found!`

- [ ] **Step 4: 커밋**

```bash
git add lib/features/calendar/data/datasources/calendar_remote_datasource.dart \
        lib/features/calendar/data/datasources/calendar_remote_datasource_impl.dart
git commit -m "feat: CalendarRemoteDataSource에 getHolidaysByRange 추가"
```

---

## Task 6: CalendarRepository 및 Impl 업데이트 (TDD)

**Files:**
- Modify: `lib/features/calendar/domain/repositories/calendar_repository.dart`
- Modify: `lib/features/calendar/data/repositories/calendar_repository_impl.dart`
- Modify: `test/features/calendar/data/repositories/calendar_repository_impl_test.dart`

- [ ] **Step 1: 테스트에 Mock 메서드 및 holidays 검증 추가**

`test/features/calendar/data/repositories/calendar_repository_impl_test.dart`의
`MockCalendarRemoteDataSource` 클래스는 자동으로 `getHolidaysByRange`를 포함하게 되므로
테스트 파일에서 `getCalendarByMonth` 테스트 케이스를 아래로 교체:

```dart
import 'package:calddy/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:calddy/features/calendar/data/models/event_model.dart';
import 'package:calddy/features/calendar/data/models/holiday_model.dart';
import 'package:calddy/features/calendar/data/repositories/calendar_repository_impl.dart';
import 'package:calddy/features/calendar/domain/entities/event_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCalendarRemoteDataSource extends Mock
    implements CalendarRemoteDataSource {}

class FakeEventModel extends Fake implements EventModel {}

EventModel _dummyModel({String id = 'event-1'}) => EventModel(
      id: id,
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

final _holiday = HolidayModel(
  date: DateTime(2026, 5, 5),
  name: '어린이날',
);

void main() {
  late CalendarRepositoryImpl repository;
  late MockCalendarRemoteDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(FakeEventModel());
  });

  setUp(() {
    mockDataSource = MockCalendarRemoteDataSource();
    repository = CalendarRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('getCalendarByMonth', () {
    test('events와 holidays를 병렬로 조회하고 CalendarData를 반환한다', () async {
      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 5, 31, 23, 59, 59);
      when(() => mockDataSource.getEventsByDateRange(start, end))
          .thenAnswer((_) async => [_dummyModel()]);
      when(() => mockDataSource.getHolidaysByRange(start, end))
          .thenAnswer((_) async => [_holiday]);

      final result = await repository.getCalendarByMonth(2026, 5);

      expect(result.events.length, 1);
      expect(result.events.first.title, '테스트');
      expect(result.habits, isEmpty);
      expect(result.ranges, isEmpty);
      expect(result.holidays.length, 1);
      expect(result.holidays.first.name, '어린이날');
      verify(() => mockDataSource.getEventsByDateRange(start, end)).called(1);
      verify(() => mockDataSource.getHolidaysByRange(start, end)).called(1);
    });

    test('공휴일 없는 달은 holidays가 빈 리스트다', () async {
      final start = DateTime(2026, 5, 1);
      final end = DateTime(2026, 5, 31, 23, 59, 59);
      when(() => mockDataSource.getEventsByDateRange(start, end))
          .thenAnswer((_) async => []);
      when(() => mockDataSource.getHolidaysByRange(start, end))
          .thenAnswer((_) async => []);

      final result = await repository.getCalendarByMonth(2026, 5);

      expect(result.holidays, isEmpty);
    });
  });

  group('getCalendarByWeek', () {
    test('주 범위로 events와 holidays를 조회한다', () async {
      final weekStart = DateTime(2026, 5, 4);
      final weekEnd = weekStart
          .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      when(() => mockDataSource.getEventsByDateRange(weekStart, weekEnd))
          .thenAnswer((_) async => [_dummyModel()]);
      when(() => mockDataSource.getHolidaysByRange(weekStart, weekEnd))
          .thenAnswer((_) async => [_holiday]);

      final result = await repository.getCalendarByWeek(weekStart);

      expect(result.events.length, 1);
      expect(result.holidays.length, 1);
      expect(result.holidays.first.date, DateTime(2026, 5, 5));
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
flutter test test/features/calendar/data/repositories/calendar_repository_impl_test.dart
```

Expected: FAIL — `getHolidaysByRange` mock이 설정됐으나 repository가 아직 호출 안 함

- [ ] **Step 3: CalendarRepository 인터페이스에 메서드 추가**

`lib/features/calendar/domain/repositories/calendar_repository.dart`:
```dart
import '../entities/calendar_data.dart';
import '../entities/event_entity.dart';
import '../entities/holiday_entity.dart';

abstract interface class CalendarRepository {
  Future<CalendarData> getCalendarByMonth(int year, int month);
  Future<CalendarData> getCalendarByWeek(DateTime weekStart);
  Future<List<HolidayEntity>> getHolidaysByRange(DateTime start, DateTime end);
  Future<EventEntity> createEvent(EventEntity event);
  Future<List<EventEntity>> createHabitInstances(EventEntity template);
  Future<EventEntity> updateEvent(EventEntity event);
  Future<List<EventEntity>> updateRecurringEvent({
    required EventEntity event,
    required bool thisAndFuture,
  });
  Future<void> deleteEvent(String eventId);
  Future<EventEntity> completeEvent(String eventId);
}
```

- [ ] **Step 4: CalendarRepositoryImpl 업데이트**

`lib/features/calendar/data/repositories/calendar_repository_impl.dart`에서 아래 부분을 교체:

**import 추가** (파일 상단):
```dart
import '../models/holiday_model.dart';
```

**`getCalendarByMonth` 교체**:
```dart
  @override
  Future<CalendarData> getCalendarByMonth(int year, int month) =>
      _guard(() async {
        final start = DateTime(year, month, 1);
        final end = DateTime(year, month + 1, 0, 23, 59, 59);
        // 두 Future를 동시에 시작해 병렬 처리 (Future.wait은 혼합 타입 캐스트 불안정)
        final eventsFuture = _dataSource.getEventsByDateRange(start, end);
        final holidaysFuture = _dataSource.getHolidaysByRange(start, end);
        final events = await eventsFuture;
        final holidays = await holidaysFuture;
        return _toCalendarData(events, holidays);
      });
```

**`getCalendarByWeek` 교체**:
```dart
  @override
  Future<CalendarData> getCalendarByWeek(DateTime weekStart) =>
      _guard(() async {
        final end = weekStart
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        final eventsFuture = _dataSource.getEventsByDateRange(weekStart, end);
        final holidaysFuture = _dataSource.getHolidaysByRange(weekStart, end);
        final events = await eventsFuture;
        final holidays = await holidaysFuture;
        return _toCalendarData(events, holidays);
      });
```

**`getHolidaysByRange` 구현 추가** (`completeEvent` 위에):
```dart
  @override
  Future<List<HolidayEntity>> getHolidaysByRange(
          DateTime start, DateTime end) =>
      _guard(() async {
        final models = await _dataSource.getHolidaysByRange(start, end);
        return models.map((m) => m.toEntity()).toList();
      });
```

**`_toCalendarData` 시그니처 교체**:
```dart
  CalendarData _toCalendarData(
          List<EventModel> all, List<HolidayModel> holidays) =>
      CalendarData(
        events: all.where((e) => e.eventType == EventType.event).toList(),
        habits: all.where((e) => e.eventType == EventType.habit).toList(),
        ranges: all.where((e) => e.eventType == EventType.range).toList(),
        holidays: holidays.map((h) => h.toEntity()).toList(),
      );
```

- [ ] **Step 5: 테스트 통과 확인**

```bash
flutter test test/features/calendar/data/repositories/calendar_repository_impl_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: 전체 Calendar 테스트 통과 확인**

```bash
flutter test test/features/calendar/
```

Expected: `All tests passed!`

- [ ] **Step 7: 커밋**

```bash
git add lib/features/calendar/domain/repositories/calendar_repository.dart \
        lib/features/calendar/data/repositories/calendar_repository_impl.dart \
        test/features/calendar/data/repositories/calendar_repository_impl_test.dart
git commit -m "feat: CalendarRepository에 holidays 병렬 조회 통합"
```

---

## Task 7: 전체 테스트 및 정적 분석

**Files:** 없음

- [ ] **Step 1: 프로젝트 전체 정적 분석**

```bash
dart analyze lib/
```

Expected: `No issues found!`

- [ ] **Step 2: 전체 테스트 실행**

```bash
flutter test
```

Expected: `All tests passed!`

- [ ] **Step 3: 최종 커밋**

```bash
git add -A
git commit -m "chore: Calendar P2 공휴일 연동 완료"
```
