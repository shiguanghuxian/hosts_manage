import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

final LocaleReducer = combineReducers<String>([
  TypedReducer<String, UpdateLocaleAction>(_updateLoaded),
]);

/// 更新全局对象时候调用的方法
String _updateLoaded(String locale, action) {
  locale = action.locale;
  if (locale == null) {
    return 'zh';
  }
  SharedPreferences.getInstance().then((SharedPreferences prefs) async {
    bool ok = await prefs.setString("locale", locale);
    if (ok) {
      print('存储语言到磁盘成功');
    }
  });
  return locale;
}

class UpdateLocaleAction {
  final String locale;
  UpdateLocaleAction(this.locale);
}
