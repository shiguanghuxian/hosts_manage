import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

final HostsMutexReducer = combineReducers<bool>([
  TypedReducer<bool, UpdateHostsMutexAction>(_updateLoaded),
]);

/// 更新全局对象时候调用的方法
bool _updateLoaded(bool hostsMutex, action) {
  hostsMutex = action.hostsMutex;
  if (hostsMutex == null) {
    return false;
  }
  SharedPreferences.getInstance().then((SharedPreferences prefs) async {
    String hostsMutexStr = "false";
    if (hostsMutex) {
      hostsMutexStr = "true";
    }
    bool ok = await prefs.setString("hostsmutex", hostsMutexStr);
    if (ok) {
      print('存储hosts是否互斥到磁盘成功');
    }
  });
  return hostsMutex;
}

class UpdateHostsMutexAction {
  final bool hostsMutex;
  UpdateHostsMutexAction(this.hostsMutex);
}
