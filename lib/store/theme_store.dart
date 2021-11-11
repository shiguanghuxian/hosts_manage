import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ThemeReducer = combineReducers<String>([
  TypedReducer<String, UpdateThemeAction>(_updateLoaded),
]);

/// 更新全局对象时候调用的方法
String _updateLoaded(String theme, action) {
  theme = action.theme;
  if (theme == null) {
    return 'auto';
  }
  SharedPreferences.getInstance().then((SharedPreferences prefs) async {
    bool ok = await prefs.setString("theme", theme);
    if (ok) {
      print('存储主题到磁盘成功');
    }
  });
  return theme;
}

class UpdateThemeAction {
  final String theme;
  UpdateThemeAction(this.theme);
}
