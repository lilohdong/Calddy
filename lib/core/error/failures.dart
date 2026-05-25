// Failure 배럴 파일
//
// 새 도메인 Failure 추가 시:
//   1. lib/core/error/failures/<feature>_failure.dart 파일 생성
//   2. 아래 export 한 줄 추가
//
// 기존 import 'package:calddy/core/error/failures.dart' 구문은 변경 불필요.
export 'failures/auth_failure.dart';
export 'failures/calendar_failure.dart';
export 'failures/appointment_failure.dart';
export 'failures/drawing_failure.dart';
export 'failures/friend_failure.dart';
export 'failures/map_failure.dart';
