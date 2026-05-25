# Map 백엔드 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Map 도메인 백엔드 전체 구현 — 지리적 중간 지점 계산(ODsay 대중교통 소요시간 포함) + Google Maps 장소 검색

**Architecture:** Domain → Data → Edge Function 레이어. `calculate-midpoint` Edge Function은 ODsay API로 각 참여자의 대중교통 소요시간을 조회하고, `search-places` Edge Function은 Google Maps Places API를 호출한다. Flutter DataSource는 `functions.invoke()`로 두 함수를 호출한다.

**Tech Stack:** Dart 3 (sealed class, interface), Flutter Riverpod, Supabase Edge Functions (Deno/TypeScript), ODsay API, Google Maps Places API, mocktail (테스트)

---

## 파일 구조

### 신규 생성
```
lib/features/map/
  domain/
    entities/
      place_entity.dart
      midpoint_result_entity.dart
    repositories/
      map_repository.dart
    usecases/
      calculate_midpoint_usecase.dart
      search_places_usecase.dart
  data/
    models/
      place_model.dart
      midpoint_result_model.dart
    datasources/
      map_remote_datasource.dart
      map_remote_datasource_impl.dart
    repositories/
      map_repository_impl.dart
  presentation/
    providers/
      map_provider.dart

test/features/map/
  domain/usecases/
    map_usecases_test.dart
  data/
    models/
      place_model_test.dart
      midpoint_result_model_test.dart
    repositories/
      map_repository_impl_test.dart

supabase/functions/
  calculate-midpoint/
    index.ts
  search-places/
    index.ts
```

### 수정
```
lib/core/error/failures.dart   ← MapFailure sealed class 추가
```

---

## Task 1: feat/map 브랜치 생성

- [ ] **Step 1: 브랜치 생성 및 이동**

```bash
git checkout -b feat/map
```

Expected: `Switched to a new branch 'feat/map'`

---

## Task 2: MapFailure 추가 (`lib/core/error/failures.dart`)

**Files:**
- Modify: `lib/core/error/failures.dart`

- [ ] **Step 1: failures.dart 끝에 MapFailure sealed class 추가**

`lib/core/error/failures.dart` 파일 끝에 아래 내용을 추가한다:

```dart
// ── Map Failures ───────────────────────────────────────────────────────────

sealed class MapFailure implements Exception {
  final String message;
  const MapFailure(this.message);
}

/// 약속을 찾을 수 없거나 참여자가 없음
final class MapAppointmentNotFoundFailure extends MapFailure {
  const MapAppointmentNotFoundFailure()
      : super('약속 정보를 찾을 수 없습니다.');
}

/// Edge Function 서버 오류 (Google Maps / ODsay API 포함)
final class MapServerFailure extends MapFailure {
  const MapServerFailure(super.message);
}

/// 분류되지 않은 오류
final class MapUnknownFailure extends MapFailure {
  const MapUnknownFailure()
      : super('알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
}
```

- [ ] **Step 2: 컴파일 확인**

```bash
flutter analyze lib/core/error/failures.dart
```

Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/core/error/failures.dart
git commit -m "feat(map): MapFailure sealed class 추가"
```

---

## Task 3: Domain 엔티티

**Files:**
- Create: `lib/features/map/domain/entities/place_entity.dart`
- Create: `lib/features/map/domain/entities/midpoint_result_entity.dart`

- [ ] **Step 1: `place_entity.dart` 작성**

```dart
class PlaceEntity {
  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double? distanceFromMidpoint;

  const PlaceEntity({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.distanceFromMidpoint,
  });
}
```

- [ ] **Step 2: `midpoint_result_entity.dart` 작성**

```dart
class ParticipantTravelEntity {
  final String userId;
  final String nickname;
  final int? travelMinutes; // null = 출발지 미설정 또는 ODsay 조회 실패

  const ParticipantTravelEntity({
    required this.userId,
    required this.nickname,
    this.travelMinutes,
  });
}

class MidpointResultEntity {
  final double lat;
  final double lng;
  final List<ParticipantTravelEntity> participants;

  const MidpointResultEntity({
    required this.lat,
    required this.lng,
    required this.participants,
  });
}
```

- [ ] **Step 3: 컴파일 확인**

```bash
flutter analyze lib/features/map/domain/entities/
```

Expected: `No issues found!`

- [ ] **Step 4: 커밋**

```bash
git add lib/features/map/domain/entities/
git commit -m "feat(map): PlaceEntity + MidpointResultEntity 정의"
```

---

## Task 4: MapRepository 인터페이스

**Files:**
- Create: `lib/features/map/domain/repositories/map_repository.dart`

- [ ] **Step 1: `map_repository.dart` 작성**

```dart
import '../entities/midpoint_result_entity.dart';
import '../entities/place_entity.dart';

abstract interface class MapRepository {
  Future<MidpointResultEntity> calculateMidpoint(String appointmentId);

  Future<List<PlaceEntity>> searchPlaces({
    required double lat,
    required double lng,
    String? keyword,
    int radius = 1000,
  });
}
```

- [ ] **Step 2: 컴파일 확인**

```bash
flutter analyze lib/features/map/domain/repositories/
```

Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/features/map/domain/repositories/map_repository.dart
git commit -m "feat(map): MapRepository 인터페이스 정의"
```

---

## Task 5: UseCase + 테스트

**Files:**
- Create: `lib/features/map/domain/usecases/calculate_midpoint_usecase.dart`
- Create: `lib/features/map/domain/usecases/search_places_usecase.dart`
- Create: `test/features/map/domain/usecases/map_usecases_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/features/map/domain/usecases/map_usecases_test.dart`:

```dart
import 'package:calddy/features/map/domain/entities/midpoint_result_entity.dart';
import 'package:calddy/features/map/domain/entities/place_entity.dart';
import 'package:calddy/features/map/domain/repositories/map_repository.dart';
import 'package:calddy/features/map/domain/usecases/calculate_midpoint_usecase.dart';
import 'package:calddy/features/map/domain/usecases/search_places_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMapRepository extends Mock implements MapRepository {}

const _dummyMidpoint = MidpointResultEntity(
  lat: 37.5,
  lng: 127.0,
  participants: [
    ParticipantTravelEntity(userId: 'u1', nickname: '동준', travelMinutes: 20),
  ],
);

const _dummyPlace = PlaceEntity(
  placeId: 'p1',
  name: '스타벅스 강남점',
  address: '서울시 강남구',
  lat: 37.498,
  lng: 127.027,
  distanceFromMidpoint: 350.0,
);

void main() {
  late MockMapRepository repo;

  setUp(() {
    repo = MockMapRepository();
  });

  group('CalculateMidpointUseCase', () {
    test('repository.calculateMidpoint을 1회 호출하고 결과를 반환한다', () async {
      when(() => repo.calculateMidpoint('appt-1'))
          .thenAnswer((_) async => _dummyMidpoint);

      final useCase = CalculateMidpointUseCase(repo);
      final result = await useCase(
        const CalculateMidpointParams(appointmentId: 'appt-1'),
      );

      expect(result.lat, 37.5);
      expect(result.participants.length, 1);
      expect(result.participants.first.travelMinutes, 20);
      verify(() => repo.calculateMidpoint('appt-1')).called(1);
    });
  });

  group('SearchPlacesUseCase', () {
    test('repository.searchPlaces를 1회 호출하고 결과를 반환한다', () async {
      when(() => repo.searchPlaces(
            lat: 37.5,
            lng: 127.0,
            keyword: '카페',
            radius: 1000,
          )).thenAnswer((_) async => [_dummyPlace]);

      final useCase = SearchPlacesUseCase(repo);
      final result = await useCase(
        const SearchPlacesParams(lat: 37.5, lng: 127.0, keyword: '카페'),
      );

      expect(result.length, 1);
      expect(result.first.name, '스타벅스 강남점');
      verify(() => repo.searchPlaces(
            lat: 37.5,
            lng: 127.0,
            keyword: '카페',
            radius: 1000,
          )).called(1);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
flutter test test/features/map/domain/usecases/map_usecases_test.dart
```

Expected: FAIL (클래스 미정의)

- [ ] **Step 3: `calculate_midpoint_usecase.dart` 작성**

```dart
import '../../../../core/usecase/usecase.dart';
import '../entities/midpoint_result_entity.dart';
import '../repositories/map_repository.dart';

class CalculateMidpointParams {
  final String appointmentId;
  const CalculateMidpointParams({required this.appointmentId});
}

class CalculateMidpointUseCase
    implements UseCase<MidpointResultEntity, CalculateMidpointParams> {
  final MapRepository _repository;
  CalculateMidpointUseCase(this._repository);

  @override
  Future<MidpointResultEntity> call(CalculateMidpointParams params) =>
      _repository.calculateMidpoint(params.appointmentId);
}
```

- [ ] **Step 4: `search_places_usecase.dart` 작성**

```dart
import '../../../../core/usecase/usecase.dart';
import '../entities/place_entity.dart';
import '../repositories/map_repository.dart';

class SearchPlacesParams {
  final double lat;
  final double lng;
  final String? keyword;
  final int radius;

  const SearchPlacesParams({
    required this.lat,
    required this.lng,
    this.keyword,
    this.radius = 1000,
  });
}

class SearchPlacesUseCase
    implements UseCase<List<PlaceEntity>, SearchPlacesParams> {
  final MapRepository _repository;
  SearchPlacesUseCase(this._repository);

  @override
  Future<List<PlaceEntity>> call(SearchPlacesParams params) =>
      _repository.searchPlaces(
        lat: params.lat,
        lng: params.lng,
        keyword: params.keyword,
        radius: params.radius,
      );
}
```

- [ ] **Step 5: 테스트 통과 확인**

```bash
flutter test test/features/map/domain/usecases/map_usecases_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: 커밋**

```bash
git add lib/features/map/domain/usecases/ test/features/map/domain/
git commit -m "feat(map): CalculateMidpointUseCase + SearchPlacesUseCase 구현 및 테스트"
```

---

## Task 6: Data Models + 테스트

**Files:**
- Create: `lib/features/map/data/models/place_model.dart`
- Create: `lib/features/map/data/models/midpoint_result_model.dart`
- Create: `test/features/map/data/models/place_model_test.dart`
- Create: `test/features/map/data/models/midpoint_result_model_test.dart`

- [ ] **Step 1: `place_model.dart` 작성**

```dart
import '../../domain/entities/place_entity.dart';

class PlaceModel extends PlaceEntity {
  const PlaceModel({
    required super.placeId,
    required super.name,
    required super.address,
    required super.lat,
    required super.lng,
    super.distanceFromMidpoint,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      placeId: json['placeId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      distanceFromMidpoint: json['distanceFromMidpoint'] != null
          ? (json['distanceFromMidpoint'] as num).toDouble()
          : null,
    );
  }
}
```

- [ ] **Step 2: `midpoint_result_model.dart` 작성**

```dart
import '../../domain/entities/midpoint_result_entity.dart';

class ParticipantTravelModel extends ParticipantTravelEntity {
  const ParticipantTravelModel({
    required super.userId,
    required super.nickname,
    super.travelMinutes,
  });

  factory ParticipantTravelModel.fromJson(Map<String, dynamic> json) {
    return ParticipantTravelModel(
      userId: json['userId'] as String,
      nickname: json['nickname'] as String,
      travelMinutes: json['travelMinutes'] as int?,
    );
  }
}

class MidpointResultModel extends MidpointResultEntity {
  const MidpointResultModel({
    required super.lat,
    required super.lng,
    required super.participants,
  });

  factory MidpointResultModel.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'] as List<dynamic>;
    return MidpointResultModel(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      participants: rawParticipants
          .map((p) => ParticipantTravelModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

- [ ] **Step 3: 모델 테스트 작성**

`test/features/map/data/models/place_model_test.dart`:

```dart
import 'package:calddy/features/map/data/models/place_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaceModel.fromJson', () {
    test('distanceFromMidpoint 포함 JSON을 올바르게 파싱한다', () {
      final json = {
        'placeId': 'p1',
        'name': '스타벅스 강남점',
        'address': '서울시 강남구',
        'lat': 37.498,
        'lng': 127.027,
        'distanceFromMidpoint': 350.5,
      };

      final model = PlaceModel.fromJson(json);

      expect(model.placeId, 'p1');
      expect(model.name, '스타벅스 강남점');
      expect(model.lat, 37.498);
      expect(model.distanceFromMidpoint, 350.5);
    });

    test('distanceFromMidpoint가 null인 JSON도 파싱한다', () {
      final json = {
        'placeId': 'p2',
        'name': '카페베네',
        'address': '서울시 서초구',
        'lat': 37.5,
        'lng': 127.0,
      };

      final model = PlaceModel.fromJson(json);

      expect(model.distanceFromMidpoint, isNull);
    });
  });
}
```

`test/features/map/data/models/midpoint_result_model_test.dart`:

```dart
import 'package:calddy/features/map/data/models/midpoint_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MidpointResultModel.fromJson', () {
    test('참여자 포함 JSON을 올바르게 파싱한다', () {
      final json = {
        'lat': 37.5,
        'lng': 127.0,
        'participants': [
          {'userId': 'u1', 'nickname': '동준', 'travelMinutes': 24},
          {'userId': 'u2', 'nickname': '지현', 'travelMinutes': null},
        ],
      };

      final model = MidpointResultModel.fromJson(json);

      expect(model.lat, 37.5);
      expect(model.participants.length, 2);
      expect(model.participants[0].travelMinutes, 24);
      expect(model.participants[1].travelMinutes, isNull);
    });
  });
}
```

- [ ] **Step 4: 테스트 실행**

```bash
flutter test test/features/map/data/models/
```

Expected: `All tests passed!`

- [ ] **Step 5: 커밋**

```bash
git add lib/features/map/data/models/ test/features/map/data/models/
git commit -m "feat(map): PlaceModel + MidpointResultModel fromJson 구현 및 테스트"
```

---

## Task 7: MapRemoteDataSource

**Files:**
- Create: `lib/features/map/data/datasources/map_remote_datasource.dart`
- Create: `lib/features/map/data/datasources/map_remote_datasource_impl.dart`

- [ ] **Step 1: `map_remote_datasource.dart` (abstract) 작성**

```dart
import '../models/midpoint_result_model.dart';
import '../models/place_model.dart';

abstract interface class MapRemoteDataSource {
  Future<MidpointResultModel> calculateMidpoint(String appointmentId);

  Future<List<PlaceModel>> searchPlaces({
    required double lat,
    required double lng,
    String? keyword,
    int radius,
  });
}
```

- [ ] **Step 2: `map_remote_datasource_impl.dart` 작성**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/midpoint_result_model.dart';
import '../models/place_model.dart';
import 'map_remote_datasource.dart';

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final SupabaseClient _supabase;
  MapRemoteDataSourceImpl(this._supabase);

  @override
  Future<MidpointResultModel> calculateMidpoint(String appointmentId) async {
    final response = await _supabase.functions.invoke(
      'calculate-midpoint',
      body: {'appointment_id': appointmentId},
    );
    if (response.status != 200) {
      throw FunctionException(
        status: response.status,
        details: response.data?.toString(),
      );
    }
    return MidpointResultModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<PlaceModel>> searchPlaces({
    required double lat,
    required double lng,
    String? keyword,
    int radius = 1000,
  }) async {
    final response = await _supabase.functions.invoke(
      'search-places',
      body: {
        'lat': lat,
        'lng': lng,
        if (keyword != null) 'keyword': keyword,
        'radius': radius,
      },
    );
    if (response.status != 200) {
      throw FunctionException(
        status: response.status,
        details: response.data?.toString(),
      );
    }
    final list = response.data as List<dynamic>;
    return list
        .map((e) => PlaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 3: 컴파일 확인**

```bash
flutter analyze lib/features/map/data/datasources/
```

Expected: `No issues found!`

- [ ] **Step 4: 커밋**

```bash
git add lib/features/map/data/datasources/
git commit -m "feat(map): MapRemoteDataSource 인터페이스 및 Impl 구현"
```

---

## Task 8: MapRepositoryImpl + 테스트

**Files:**
- Create: `lib/features/map/data/repositories/map_repository_impl.dart`
- Create: `test/features/map/data/repositories/map_repository_impl_test.dart`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/features/map/data/repositories/map_repository_impl_test.dart`:

```dart
import 'package:calddy/core/error/failures.dart';
import 'package:calddy/features/map/data/datasources/map_remote_datasource.dart';
import 'package:calddy/features/map/data/models/midpoint_result_model.dart';
import 'package:calddy/features/map/data/models/place_model.dart';
import 'package:calddy/features/map/data/repositories/map_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockMapRemoteDataSource extends Mock implements MapRemoteDataSource {}

const _dummyMidpoint = MidpointResultModel(
  lat: 37.5,
  lng: 127.0,
  participants: [
    ParticipantTravelModel(userId: 'u1', nickname: '동준', travelMinutes: 20),
  ],
);

const _dummyPlace = PlaceModel(
  placeId: 'p1',
  name: '스타벅스 강남점',
  address: '서울시 강남구',
  lat: 37.498,
  lng: 127.027,
);

void main() {
  late MapRepositoryImpl repository;
  late MockMapRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockMapRemoteDataSource();
    repository = MapRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('calculateMidpoint', () {
    test('DataSource 결과를 그대로 반환한다', () async {
      when(() => mockDataSource.calculateMidpoint('appt-1'))
          .thenAnswer((_) async => _dummyMidpoint);

      final result = await repository.calculateMidpoint('appt-1');

      expect(result.lat, 37.5);
      expect(result.participants.first.travelMinutes, 20);
      verify(() => mockDataSource.calculateMidpoint('appt-1')).called(1);
    });

    test('FunctionException(404) → MapAppointmentNotFoundFailure', () async {
      when(() => mockDataSource.calculateMidpoint('appt-1')).thenThrow(
        FunctionException(status: 404, details: 'not found'),
      );

      expect(
        () => repository.calculateMidpoint('appt-1'),
        throwsA(isA<MapAppointmentNotFoundFailure>()),
      );
    });

    test('FunctionException(500) → MapServerFailure', () async {
      when(() => mockDataSource.calculateMidpoint('appt-1')).thenThrow(
        FunctionException(status: 500, details: 'internal error'),
      );

      expect(
        () => repository.calculateMidpoint('appt-1'),
        throwsA(isA<MapServerFailure>()),
      );
    });

    test('미분류 예외 → MapUnknownFailure', () async {
      when(() => mockDataSource.calculateMidpoint('appt-1'))
          .thenThrow(Exception('unknown'));

      expect(
        () => repository.calculateMidpoint('appt-1'),
        throwsA(isA<MapUnknownFailure>()),
      );
    });
  });

  group('searchPlaces', () {
    test('DataSource 결과를 그대로 반환한다', () async {
      when(() => mockDataSource.searchPlaces(
            lat: 37.5,
            lng: 127.0,
            keyword: '카페',
            radius: 1000,
          )).thenAnswer((_) async => [_dummyPlace]);

      final result = await repository.searchPlaces(
        lat: 37.5,
        lng: 127.0,
        keyword: '카페',
      );

      expect(result.length, 1);
      expect(result.first.name, '스타벅스 강남점');
    });

    test('FunctionException(500) → MapServerFailure', () async {
      when(() => mockDataSource.searchPlaces(
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            keyword: any(named: 'keyword'),
            radius: any(named: 'radius'),
          )).thenThrow(FunctionException(status: 500, details: 'api error'));

      expect(
        () => repository.searchPlaces(lat: 37.5, lng: 127.0),
        throwsA(isA<MapServerFailure>()),
      );
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
flutter test test/features/map/data/repositories/map_repository_impl_test.dart
```

Expected: FAIL (클래스 미정의)

- [ ] **Step 3: `map_repository_impl.dart` 작성**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/midpoint_result_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_datasource.dart';

class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource _remoteDataSource;

  MapRepositoryImpl({required MapRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<MidpointResultEntity> calculateMidpoint(String appointmentId) async {
    try {
      return await _remoteDataSource.calculateMidpoint(appointmentId);
    } on FunctionException catch (e) {
      if (e.status == 404) throw const MapAppointmentNotFoundFailure();
      throw MapServerFailure(e.details?.toString() ?? '서버 오류가 발생했습니다.');
    } catch (_) {
      throw const MapUnknownFailure();
    }
  }

  @override
  Future<List<PlaceEntity>> searchPlaces({
    required double lat,
    required double lng,
    String? keyword,
    int radius = 1000,
  }) async {
    try {
      return await _remoteDataSource.searchPlaces(
        lat: lat,
        lng: lng,
        keyword: keyword,
        radius: radius,
      );
    } on FunctionException catch (e) {
      throw MapServerFailure(e.details?.toString() ?? '장소 검색 중 오류가 발생했습니다.');
    } catch (_) {
      throw const MapUnknownFailure();
    }
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
flutter test test/features/map/data/repositories/map_repository_impl_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: 커밋**

```bash
git add lib/features/map/data/repositories/ test/features/map/data/repositories/
git commit -m "feat(map): MapRepositoryImpl 구현 및 예외 매핑 테스트"
```

---

## Task 9: Riverpod Provider 체인

**Files:**
- Create: `lib/features/map/presentation/providers/map_provider.dart`

- [ ] **Step 1: `map_provider.dart` 작성**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/map_remote_datasource_impl.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/usecases/calculate_midpoint_usecase.dart';
import '../../domain/usecases/search_places_usecase.dart';

final mapRemoteDataSourceProvider = Provider((ref) {
  return MapRemoteDataSourceImpl(Supabase.instance.client);
});

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepositoryImpl(
    remoteDataSource: ref.watch(mapRemoteDataSourceProvider),
  );
});

final calculateMidpointUseCaseProvider = Provider((ref) {
  return CalculateMidpointUseCase(ref.watch(mapRepositoryProvider));
});

final searchPlacesUseCaseProvider = Provider((ref) {
  return SearchPlacesUseCase(ref.watch(mapRepositoryProvider));
});
```

- [ ] **Step 2: 컴파일 확인**

```bash
flutter analyze lib/features/map/
```

Expected: `No issues found!`

- [ ] **Step 3: 전체 테스트 확인**

```bash
flutter test test/features/map/
```

Expected: `All tests passed!`

- [ ] **Step 4: 커밋**

```bash
git add lib/features/map/presentation/providers/map_provider.dart
git commit -m "feat(map): Riverpod Provider 체인 구성"
```

---

## Task 10: Edge Function — `calculate-midpoint`

**Files:**
- Create: `supabase/functions/calculate-midpoint/index.ts`

> Supabase Vault에 `ODSAY_API_KEY`가 등록되어 있어야 한다. 없으면 Supabase 대시보드 → Project Settings → Vault → New Secret에서 추가.

- [ ] **Step 1: `index.ts` 작성**

```typescript
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const { appointment_id } = await req.json();
  if (!appointment_id) {
    return new Response(JSON.stringify({ error: 'appointment_id required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  // 1. 약속 참여자 수집 (creator + invitees)
  const { data: appointment, error: apptError } = await supabase
    .from('appointments')
    .select('creator_id, appointment_invites(invitee_id)')
    .eq('id', appointment_id)
    .single();

  if (apptError || !appointment) {
    return new Response(JSON.stringify({ error: 'appointment not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const participantIds: string[] = [
    appointment.creator_id,
    ...appointment.appointment_invites.map((i: { invitee_id: string }) => i.invitee_id),
  ];

  // 2. profiles에서 좌표 및 닉네임 조회
  const { data: profiles } = await supabase
    .from('profiles')
    .select('id, nickname, home_lat, home_lng')
    .in('id', participantIds);

  if (!profiles || profiles.length === 0) {
    return new Response(JSON.stringify({ error: 'no participants found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // 3. 좌표가 있는 참여자만 필터링 후 중간 지점 계산
  const withLocation = profiles.filter(
    (p: { home_lat: number | null; home_lng: number | null }) =>
      p.home_lat != null && p.home_lng != null,
  );

  const midLat = withLocation.reduce((sum: number, p: { home_lat: number }) => sum + p.home_lat, 0) / withLocation.length;
  const midLng = withLocation.reduce((sum: number, p: { home_lng: number }) => sum + p.home_lng, 0) / withLocation.length;

  // 4. ODsay 대중교통 소요 시간 병렬 조회
  const odsayKey = Deno.env.get('ODSAY_API_KEY')!;

  const participants = await Promise.all(
    profiles.map(async (p: { id: string; nickname: string; home_lat: number | null; home_lng: number | null }) => {
      if (p.home_lat == null || p.home_lng == null) {
        return { userId: p.id, nickname: p.nickname, travelMinutes: null };
      }
      try {
        const url = `https://api.odsay.com/v1/api/searchPubTransPath?SX=${p.home_lng}&SY=${p.home_lat}&EX=${midLng}&EY=${midLat}&apiKey=${odsayKey}`;
        const res = await fetch(url);
        const json = await res.json();
        const totalTime = json?.result?.path?.[0]?.info?.totalTime ?? null;
        return { userId: p.id, nickname: p.nickname, travelMinutes: totalTime };
      } catch {
        return { userId: p.id, nickname: p.nickname, travelMinutes: null };
      }
    }),
  );

  return new Response(
    JSON.stringify({ lat: midLat, lng: midLng, participants }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  );
});
```

- [ ] **Step 2: Edge Function 배포**

```bash
supabase functions deploy calculate-midpoint
```

Expected: `Deployed successfully`

- [ ] **Step 3: Vault에 ODSAY_API_KEY 등록 확인**

Supabase 대시보드 → Project Settings → Vault에 `ODSAY_API_KEY`가 있는지 확인한다. 없으면 odsay.com에서 발급한 키를 등록한다.

- [ ] **Step 4: 수동 테스트 (실제 appointment_id로 교체)**

```bash
curl -X POST \
  'https://<project-ref>.supabase.co/functions/v1/calculate-midpoint' \
  -H 'Authorization: Bearer <anon-key>' \
  -H 'Content-Type: application/json' \
  -d '{"appointment_id": "<실제-uuid>"}'
```

Expected: `{"lat":37.5,"lng":127.0,"participants":[{"userId":"...","nickname":"...","travelMinutes":24}]}`

- [ ] **Step 5: 커밋**

```bash
git add supabase/functions/calculate-midpoint/
git commit -m "feat(map): calculate-midpoint Edge Function (ODsay 대중교통 소요시간)"
```

---

## Task 11: Edge Function — `search-places`

**Files:**
- Create: `supabase/functions/search-places/index.ts`

> Supabase Vault에 `GOOGLE_MAPS_API_KEY`가 등록되어 있어야 한다. Google Cloud Console에서 Places API가 활성화된 키여야 한다.

- [ ] **Step 1: Haversine 공식 헬퍼 포함 `index.ts` 작성**

```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function haversineMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371000;
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLng = (lng2 - lng1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const { lat, lng, keyword, radius = 1000 } = await req.json();
  if (lat == null || lng == null) {
    return new Response(JSON.stringify({ error: 'lat, lng required' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const apiKey = Deno.env.get('GOOGLE_MAPS_API_KEY')!;
  const params = new URLSearchParams({
    location: `${lat},${lng}`,
    radius: String(radius),
    language: 'ko',
    key: apiKey,
  });
  if (keyword) params.set('keyword', keyword);

  const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?${params}`;
  const res = await fetch(url);

  if (!res.ok) {
    return new Response(JSON.stringify({ error: 'Google Maps API error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const json = await res.json();

  if (json.status !== 'OK' && json.status !== 'ZERO_RESULTS') {
    return new Response(JSON.stringify({ error: json.status }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const results = (json.results ?? []).slice(0, 20).map((place: {
    place_id: string;
    name: string;
    vicinity: string;
    geometry: { location: { lat: number; lng: number } };
  }) => ({
    placeId: place.place_id,
    name: place.name,
    address: place.vicinity,
    lat: place.geometry.location.lat,
    lng: place.geometry.location.lng,
    distanceFromMidpoint: haversineMeters(lat, lng, place.geometry.location.lat, place.geometry.location.lng),
  }));

  results.sort((a: { distanceFromMidpoint: number }, b: { distanceFromMidpoint: number }) =>
    a.distanceFromMidpoint - b.distanceFromMidpoint,
  );

  return new Response(JSON.stringify(results), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
```

- [ ] **Step 2: Edge Function 배포**

```bash
supabase functions deploy search-places
```

Expected: `Deployed successfully`

- [ ] **Step 3: Vault에 GOOGLE_MAPS_API_KEY 확인**

Supabase 대시보드 → Project Settings → Vault에 `GOOGLE_MAPS_API_KEY`가 있는지 확인한다. 없으면 Google Cloud Console → APIs & Services → Credentials에서 Places API가 활성화된 키를 등록한다.

- [ ] **Step 4: 수동 테스트**

```bash
curl -X POST \
  'https://<project-ref>.supabase.co/functions/v1/search-places' \
  -H 'Authorization: Bearer <anon-key>' \
  -H 'Content-Type: application/json' \
  -d '{"lat": 37.4979, "lng": 127.0276, "keyword": "카페", "radius": 500}'
```

Expected: `[{"placeId":"...","name":"...","address":"...","lat":...,"lng":...,"distanceFromMidpoint":...}]`

- [ ] **Step 5: 커밋**

```bash
git add supabase/functions/search-places/
git commit -m "feat(map): search-places Edge Function (Google Maps Places API)"
```

---

## Task 12: 전체 검증 및 브랜치 마무리

- [ ] **Step 1: 전체 테스트 실행**

```bash
flutter test test/features/map/
```

Expected: `All tests passed!`

- [ ] **Step 2: 전체 정적 분석**

```bash
flutter analyze lib/features/map/ lib/core/error/failures.dart
```

Expected: `No issues found!`

- [ ] **Step 3: 구현 완료 확인 체크리스트**

- [ ] `lib/features/map/domain/entities/place_entity.dart` 존재
- [ ] `lib/features/map/domain/entities/midpoint_result_entity.dart` 존재
- [ ] `lib/features/map/domain/repositories/map_repository.dart` 존재
- [ ] `lib/features/map/domain/usecases/calculate_midpoint_usecase.dart` 존재
- [ ] `lib/features/map/domain/usecases/search_places_usecase.dart` 존재
- [ ] `lib/features/map/data/models/place_model.dart` 존재
- [ ] `lib/features/map/data/models/midpoint_result_model.dart` 존재
- [ ] `lib/features/map/data/datasources/map_remote_datasource.dart` 존재
- [ ] `lib/features/map/data/datasources/map_remote_datasource_impl.dart` 존재
- [ ] `lib/features/map/data/repositories/map_repository_impl.dart` 존재
- [ ] `lib/features/map/presentation/providers/map_provider.dart` 존재
- [ ] `supabase/functions/calculate-midpoint/index.ts` 배포 완료
- [ ] `supabase/functions/search-places/index.ts` 배포 완료
- [ ] `domain/` 레이어에 supabase/flutter import 없음
