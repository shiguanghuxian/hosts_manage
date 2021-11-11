import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/lang_store.dart';
import 'package:hosts_manage/store/locale_store.dart';
import 'package:hosts_manage/store/theme_store.dart';

class ZState {
  String locale = "en"; // 语言
  I18N lang;
  String theme = "auto"; // 语言

  ZState({
    this.locale,
    this.lang,
    this.theme,
  });
}

// 创建store使用
ZState appReducer(ZState state, action) {
  return ZState(
    // 将全局对象和action关联
    locale: LocaleReducer(state.locale, action),
    lang: LangReducer(state.lang, action),
    theme: ThemeReducer(state.theme, action),
  );
}
