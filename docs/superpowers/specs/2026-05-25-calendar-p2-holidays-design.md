# Calendar P2 – 공휴일 연동 설계

**날짜**: 2026-05-25  
**브랜치**: feat/calendar_v2  
**범위**: 백엔드(Domain + Data + UseCase + Provider) 한정. Presentation 레이어 제외.

---

## 배경

Google Drive `calddy_backend_plan_v2` 기준 Calendar P2 미완성 항목:

| 항목 | 상태 |
|------|------|
| 반복 습관 생성/수정 | ✅ 완료 |
| 구간 일정 CRUD | ✅ 완료 |
| 날짜별 드로잉 저장/조회 | ✅ 완료 (코드 존재, Sheet 미업데이트) |
| **공휴일 데이터 연동** | ❌ 미구현 |

`holidays` 테이블과 2025~2027 시드 데이터는 스키마에 존재하지만,  
Dart 레이어(Entity / Model / DataSource / Repository / UseCase)가 전혀 없는 상태.

---

## 목표

`GetCalendarByMonth` / `GetCalendarByWeek` UseCase가 반환하는 `CalendarData`에  
해당 날짜 범위의 공휴일 목록을 포함시킨다.

---

## 아키텍처

### 데이터 흐름

```
CalendarRemoteDataSource.getHolidaysByRange(start, end)
  → SELECT date, name FROM holidays WHERE date BETWEEN start AND end
  → List<HolidayModel>
  → CalendarRepositoryImpl
  → List<HolidayEntity>
  → GetCalendarByMonthUseCase / GetCalendarByWeekUseCase (Future.wait 병렬)
  → CalendarData.holidays
  → calendarProvider (기존 Provider 체인 변경 없음)
```

---

## 레이어별 변경 명세

### 1. Domain – 신규 파일

**`lib/features/calendar/domain/entities/holiday_entity.dart`**
```dart
class HolidayEntity {
  final DateTime date;
  final String name;

  const HolidayEntity({required this.date, required this.name});
}
```

**`lib/features/calendar/domain/entities/calendar_data.dart`** (수정)
```dart
class CalendarData {
  final List<EventEntity> events;
  final List<EventEntity> habits;
  final List<EventEntity> ranges;
  final List<HolidayEntity> holidays; // 추가
  ...
}
```

**`lib/features/calendar/domain/repositories/calendar_repository.dart`** (수정)  
기존 메서드에 아래 추가:
```dart
Future<List<HolidayEntity>> getHolidaysByRange(DateTime start, DateTime end);
```

---

### 2. Data – 신규/수정 파일

**`lib/features/calendar/data/models/holiday_model.dart`** (신규)
```dart
class HolidayModel {
  final DateTime date;
  final String name;

  HolidayModel.fromJson(Map<String, dynamic> json)
      : date = DateTime.parse(json['date'] as String),
        name = json['name'] as String;

  HolidayEntity toEntity() => HolidayEntity(date: date, name: name);
}
```

**`lib/features/calendar/data/datasources/calendar_remote_datasource.dart`** (수정)  
abstract에 아래 추가:
```dart
Future<List<HolidayModel>> getHolidaysByRange(DateTime start, DateTime end);
```

**`lib/features/calendar/data/datasources/calendar_remote_datasource_impl.dart`** (수정)  
구현체에 아래 추가:
```dart
@override
Future<List<HolidayModel>> getHolidaysByRange(DateTime start, DateTime end) async {
  final startStr = _dateStr(start);
  final endStr = _dateStr(end);
  final rows = await _client
      .from(SupabaseConstants.holidays)
      .select('date, name')
      .gte('date', startStr)
      .lte('date', endStr)
      .order('date');
  return rows.map(HolidayModel.fromJson).toList();
}
```

**`lib/features/calendar/data/repositories/calendar_repository_impl.dart`** (수정)
```dart
@override
Future<List<HolidayEntity>> getHolidaysByRange(DateTime start, DateTime end) async {
  final models = await remoteDataSource.getHolidaysByRange(start, end);
  return models.map((m) => m.toEntity()).toList();
}
```

---

### 3. UseCase – 수정

`GetCalendarByMonthUseCase` / `GetCalendarByWeekUseCase` 모두 동일한 패턴:

```dart
final results = await Future.wait([
  _repository.getEvents(start, end),
  _repository.getHabits(start, end),
  _repository.getRanges(start, end),
  _repository.getHolidaysByRange(start, end),  // 추가
]);

return CalendarData(
  events: results[0] as List<EventEntity>,
  habits: results[1] as List<EventEntity>,
  ranges: results[2] as List<EventEntity>,
  holidays: results[3] as List<HolidayEntity>,  // 추가
);
```

---

### 4. Provider – 변경 없음

`CalendarData`에 holidays가 포함되므로 기존 `calendarProvider` 체인 그대로 사용.  
Presentation에서 `calendarData.holidays`로 접근 가능.

---

## DB 스키마 (기존 테이블, 변경 없음)

```sql
create table public.holidays (
  date  date primary key,
  name  text not null
);
-- 2025~2027 시드 데이터 존재
-- RLS: 인증 유저 전체 조회 허용
```

---

## 수정 파일 목록

| 파일 | 변경 유형 |
|------|-----------|
| `domain/entities/holiday_entity.dart` | 신규 |
| `domain/entities/calendar_data.dart` | 수정 (holidays 필드 추가) |
| `domain/repositories/calendar_repository.dart` | 수정 (메서드 추가) |
| `data/models/holiday_model.dart` | 신규 |
| `data/datasources/calendar_remote_datasource.dart` | 수정 (추상 메서드 추가) |
| `data/datasources/calendar_remote_datasource_impl.dart` | 수정 (구현 추가) |
| `data/repositories/calendar_repository_impl.dart` | 수정 (구현 추가) |
| `domain/usecases/get_calendar_by_month_usecase.dart` | 수정 |
| `domain/usecases/get_calendar_by_week_usecase.dart` | 수정 |

---

## 완료 기준

- `GetCalendarByMonth/WeekUseCase` 호출 시 `CalendarData.holidays`에 해당 월/주 공휴일 포함
- 공휴일 없는 기간 조회 시 빈 리스트 반환 (null 없음)
- 기존 events/habits/ranges 동작 회귀 없음
- 클린 아키텍처 레이어 위반 없음 (Domain에 Supabase import 없음)
