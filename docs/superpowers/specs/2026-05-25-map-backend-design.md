# Map 백엔드 설계 (P2)

**날짜**: 2026-05-25  
**범위**: Map 도메인 백엔드 전용 (Domain + Data + Edge Functions). Presentation 레이어 제외.  
**브랜치**: feat/map

---

## 배경 및 목적

Calddy의 약속(Appointment) 기능에서 참여자들이 만날 장소를 추천해주는 기능이 필요하다.  
- 참여자 각자의 출발지(home_lat/lng) 기준 지리적 중간 지점 계산  
- ODsay API로 각 참여자의 대중교통 소요 시간 조회 후 표시  
- Google Maps Places API로 중간 지점 근처 장소 검색

`profiles.home_lat`, `profiles.home_lng`, `appointments.suggested_place` 컬럼은 이미 DB에 존재.

---

## 데이터 흐름

```
[Flutter UseCase]
      │
      ▼
MapRepository (interface, domain)
      │
      ▼
MapRemoteDataSourceImpl (data)
      │
      ├── functions.invoke('calculate-midpoint')
      │         │
      │         ├── appointments + invites → 참여자 조회
      │         ├── profiles → home_lat/lng 조회
      │         ├── 좌표 평균 → midpoint 계산
      │         └── ODsay searchPubTransPath × N명 → travelMinutes
      │
      └── functions.invoke('search-places')
                │
                └── Google Maps Places API (Nearby Search)
```

---

## 엔티티

### PlaceEntity (기존 명세)
```dart
class PlaceEntity {
  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double? distanceFromMidpoint;
}
```

### MidpointResultEntity (신규)
```dart
class MidpointResultEntity {
  final double lat;
  final double lng;
  final List<ParticipantTravelEntity> participants;
}

class ParticipantTravelEntity {
  final String userId;
  final String nickname;
  final int travelMinutes;  // ODsay 대중교통 소요 시간
}
```

---

## Domain 레이어

### MapRepository (abstract interface)
```dart
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

### CalculateMidpointUseCase
- **입력**: `Params(String appointmentId)`
- **출력**: `MidpointResultEntity`
- **호출처**: Appointment 도메인의 `GetPlaceSuggestionUseCase` (추후 연동)

### SearchPlacesUseCase
- **입력**: `Params(double lat, double lng, String? keyword, int radius)`
- **출력**: `List<PlaceEntity>`

---

## Data 레이어

### MapRemoteDataSource (abstract)
```dart
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

### MapRemoteDataSourceImpl
- `Supabase.instance.client.functions.invoke('calculate-midpoint', body: {...})`
- `Supabase.instance.client.functions.invoke('search-places', body: {...})`
- 에러 시 `ServerException` throw

### Models
- `PlaceModel extends PlaceEntity` — `fromJson(Map<String, dynamic>)`
- `MidpointResultModel extends MidpointResultEntity` — `fromJson`
- `ParticipantTravelModel extends ParticipantTravelEntity` — `fromJson`

---

## Edge Functions

### `supabase/functions/calculate-midpoint/index.ts`

**입력**: `{ appointment_id: string }`

**처리 순서**:
1. `appointment_invites` JOIN `appointments` WHERE `appointment_id` → `invitee_id[]` + `creator_id` 수집
2. `profiles` WHERE `id IN (참여자 전원)` → `home_lat`, `home_lng`, `nickname` 조회
3. home_lat/lng가 null인 참여자 → 건너뜀 (travelMinutes: null로 반환)
4. midpoint = `{ lat: avg(home_lat), lng: avg(home_lng) }`
5. 각 참여자에 대해 ODsay `searchPubTransPath` 호출:
   ```
   GET https://api.odsay.com/v1/api/searchPubTransPath
     ?SX={user_lng}&SY={user_lat}
     &EX={mid_lng}&EY={mid_lat}
     &apiKey={ODSAY_API_KEY}
   ```
6. 응답에서 `result.path[0].info.totalTime` 추출 (분)
7. 반환:
   ```json
   { "lat": 37.5, "lng": 127.0,
     "participants": [
       { "userId": "...", "nickname": "...", "travelMinutes": 24 }
     ]
   }
   ```

**Secret**: `ODSAY_API_KEY` (Supabase Vault)  
**RLS 우회**: `SUPABASE_SERVICE_ROLE_KEY`로 profiles 조회 (Edge Function 내부 전용)

---

### `supabase/functions/search-places/index.ts`

**입력**: `{ lat: number, lng: number, keyword?: string, radius?: number }`

**처리 순서**:
1. Google Maps Places API Nearby Search 호출:
   ```
   GET https://maps.googleapis.com/maps/api/place/nearbysearch/json
     ?location={lat},{lng}&radius={radius}
     &keyword={keyword}&language=ko
     &key={GOOGLE_MAPS_API_KEY}
   ```
2. `results[]` → PlaceEntity 형식 변환
3. 각 장소의 `distanceFromMidpoint` 계산 (Haversine 공식)
4. distance 오름차순 정렬 후 반환 (최대 20개)

**Secret**: `GOOGLE_MAPS_API_KEY` (Supabase Vault)

---

## Riverpod Provider 체인

`lib/features/map/presentation/providers/map_provider.dart`

```dart
final mapRemoteDataSourceProvider = Provider<MapRemoteDataSource>((ref) {
  return MapRemoteDataSourceImpl(Supabase.instance.client);
});

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepositoryImpl(ref.watch(mapRemoteDataSourceProvider));
});

final calculateMidpointUseCaseProvider = Provider((ref) {
  return CalculateMidpointUseCase(ref.watch(mapRepositoryProvider));
});

final searchPlacesUseCaseProvider = Provider((ref) {
  return SearchPlacesUseCase(ref.watch(mapRepositoryProvider));
});
```

---

## 파일 목록 (신규 생성)

```
lib/features/map/
  domain/
    entities/
      place_entity.dart
      midpoint_result_entity.dart           ← 신규
    repositories/
      map_repository.dart
    usecases/
      calculate_midpoint_usecase.dart
      search_places_usecase.dart
  data/
    models/
      place_model.dart
      midpoint_result_model.dart            ← 신규
    datasources/
      map_remote_datasource.dart
      map_remote_datasource_impl.dart
    repositories/
      map_repository_impl.dart
  presentation/
    providers/
      map_provider.dart

supabase/functions/
  calculate-midpoint/
    index.ts                                ← 신규
  search-places/
    index.ts                                ← 신규
```

---

## 에러 처리

| 상황 | 처리 |
|------|------|
| 참여자 home_lat/lng 미설정 | travelMinutes 필드 null로 반환, 클라이언트에서 "출발지 미설정" 표시 |
| ODsay API 실패 | 해당 참여자만 travelMinutes null, 나머지는 정상 반환 |
| Google Maps API 실패 | Edge Function에서 500 반환 → `ServerException` |
| appointment_id 없음 | Edge Function에서 404 반환 → `ServerException` |

---

## 의존성 및 제약

- `profiles.home_lat`, `profiles.home_lng` 컬럼 기존 존재 ✅  
- `appointments.suggested_place` 컬럼 기존 존재 ✅  
- ODsay API Key 발급 필요 (odsay.com)  
- Google Maps API Key 기존 발급 여부 확인 필요 (Places API 활성화)  
- Appointment 도메인 `GetPlaceSuggestionUseCase`와의 연동은 별도 작업

---

## 범위 외 (이번 작업 제외)

- `PlacePickerPage` UI 구현
- Appointment 도메인 `GetPlaceSuggestionUseCase` 연동
- `appointments.suggested_place` 저장 로직 (Appointment P2 작업 시 처리)
