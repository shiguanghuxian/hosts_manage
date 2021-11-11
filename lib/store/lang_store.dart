import 'package:hosts_manage/i18n/i18n.dart';
import 'package:redux/redux.dart';

final LangReducer = combineReducers<I18N>([
  TypedReducer<I18N, UpdateLangAction>(_updateLoaded),
]);

/// 更新全局对象时候调用的方法
I18N _updateLoaded(I18N lang, action) {
  lang = action.lang;

  return lang;
}

class UpdateLangAction {
  final I18N lang;
  UpdateLangAction(this.lang);
}
