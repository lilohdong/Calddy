// 하위 호환성 유지용 re-export. 새 코드는 user_entity.dart를 import할 것.
import 'package:calddy/features/auth/domain/entities/user_entity.dart';

export 'user_entity.dart';
typedef AppUser = UserEntity;
