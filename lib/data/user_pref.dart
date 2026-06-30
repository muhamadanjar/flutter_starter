
import 'package:enterprise_flutter_app/data/pref.dart';
import 'package:enterprise_flutter_app/data/pref_group.dart';

class UserPref extends PrefGroup {
  @override
  String name = 'user_pref';

  late Pref<String?> accessToken = pref<String?>('access_token', null);
  late Pref<String?> refreshToken = pref<String?>('refresh_token', null);
  late Pref<bool> isLogin = pref<bool>('isLogin', false);
}
