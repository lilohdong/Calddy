sealed class MapFailure implements Exception {
  final String message;
  const MapFailure(this.message);
}

/// 세션 만료
final class MapSessionExpiredFailure extends MapFailure {
  const MapSessionExpiredFailure()
      : super('로그인 세션이 만료됐습니다. 다시 로그인해주세요.');
}

/// 참여자 위치 정보 없음
final class NoLocationDataFailure extends MapFailure {
  const NoLocationDataFailure()
      : super('위치 정보가 없습니다. 설정 → 내 위치를 먼저 등록해주세요.');
}

/// 약속을 찾을 수 없음
final class MapAppointmentNotFoundFailure extends MapFailure {
  const MapAppointmentNotFoundFailure()
      : super('약속을 찾을 수 없습니다.');
}

/// 외부 API 오류 (ODsay, Kakao, Gemini)
final class MapApiFailure extends MapFailure {
  const MapApiFailure(super.message);
}

/// 분류되지 않은 Map 오류
final class MapUnknownFailure extends MapFailure {
  const MapUnknownFailure(super.message);
}
