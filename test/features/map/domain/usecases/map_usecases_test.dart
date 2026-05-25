import 'package:calddy/features/map/domain/entities/midpoint_result_entity.dart';
import 'package:calddy/features/map/domain/entities/recommendation_result_entity.dart';
import 'package:calddy/features/map/domain/repositories/map_repository.dart';
import 'package:calddy/features/map/domain/usecases/calculate_midpoint_usecase.dart';
import 'package:calddy/features/map/domain/usecases/recommend_place_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMapRepository extends Mock implements MapRepository {}

final _dummyMidpoint = MidpointResultEntity(
  lat: 37.5,
  lng: 127.0,
  iterationCount: 1,
  participants: const [
    ParticipantTravel(userId: 'u1', nickname: '동준', travelMinutes: 20),
  ],
);

const _dummyRecommendation = RecommendationResultEntity(
  recommendedKeyword: '강남역',
  places: [],
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
      expect(result.iterationCount, 1);
      expect(result.participants.first.travelMinutes, 20);
      verify(() => repo.calculateMidpoint('appt-1')).called(1);
    });
  });

  group('RecommendPlaceUseCase', () {
    test('repository.recommendPlace를 1회 호출하고 결과를 반환한다', () async {
      when(() => repo.recommendPlace(_dummyMidpoint))
          .thenAnswer((_) async => _dummyRecommendation);

      final useCase = RecommendPlaceUseCase(repo);
      final result = await useCase(
        RecommendPlaceParams(midpoint: _dummyMidpoint),
      );

      expect(result.recommendedKeyword, '강남역');
      verify(() => repo.recommendPlace(_dummyMidpoint)).called(1);
    });
  });
}
