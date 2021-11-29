import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

final AutoSocks5Reducer = combineReducers<String>([
  TypedReducer<String, UpdateAutoSocks5Action>(_updateLoaded),
]);

/// 更新全局对象时候调用的方法
String _updateLoaded(String autoSocks5, action) {
  autoSocks5 = action.autoSocks5;
  SharedPreferences.getInstance().then((SharedPreferences prefs) async {
    bool ok = await prefs.setString("auto_socks5", autoSocks5);
    if (ok) {
      print('存储自动socks5到磁盘成功');
    }
  });

  return autoSocks5;
}

class UpdateAutoSocks5Action {
  final String autoSocks5;
  UpdateAutoSocks5Action(this.autoSocks5);
}
