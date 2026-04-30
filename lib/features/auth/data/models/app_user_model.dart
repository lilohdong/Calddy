// 하위 호환성 유지용 re-export. 새 코드는 user_model.dart를 import할 것.
import 'package:calddy/features/auth/data/models/user_model.dart';

export 'user_model.dart';
typedef AppUserModel = UserModel;
