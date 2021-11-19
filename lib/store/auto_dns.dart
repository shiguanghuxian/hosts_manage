import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

final AutoDNSReducer = combineReducers<String>([
  TypedReducer<String, UpdateAutoDNSAction>(_updateLoaded),
]);

/// 更新全局对象时候调用的方法
String _updateLoaded(String autoDNS, action) {
  autoDNS = action.autoDNS;
  SharedPreferences.getInstance().then((SharedPreferences prefs) async {
    bool ok = await prefs.setString("auto_dns", autoDNS);
    if (ok) {
      print('存储自动DNS到磁盘成功');
    }
  });

  return autoDNS;
}

class UpdateAutoDNSAction {
  final String autoDNS;
  UpdateAutoDNSAction(this.autoDNS);
}
