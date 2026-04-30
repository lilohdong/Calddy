/// 모든 UseCase가 구현해야 하는 추상 인터페이스
///
/// [Type] : call()의 반환 타입
/// [Params]: call()에 넘기는 파라미터 타입 (파라미터 없을 때는 [NoParams] 사용)
abstract class UseCase<Output, Params> {
  Future<Output> call(Params params);
}

/// 파라미터가 없는 UseCase에 사용하는 빈 파라미터 클래스
class NoParams {
  const NoParams();
}
