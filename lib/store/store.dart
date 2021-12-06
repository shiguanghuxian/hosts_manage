import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/auto_dns.dart';
import 'package:hosts_manage/store/auto_socks5.dart';
import 'package:hosts_manage/store/lang_store.dart';
import 'package:hosts_manage/store/locale_hostsmutex.dart';
import 'package:hosts_manage/store/locale_store.dart';
import 'package:hosts_manage/store/theme_store.dart';

class ZState {
  String locale = "en"; // 语言
  I18N lang;
  String theme = "auto"; // 语言
  String autoDNS = "false"; // 默认软件启动不打开dns
  String autoSocks5 = "false"; // 默认软件启动不打开socks5
  bool hostsMutex = false; // 默认软件启动不打开socks5

  ZState({
    this.locale,
    this.lang,
    this.theme,
    this.autoDNS,
    this.autoSocks5,
    this.hostsMutex,
  });
}

// 创建store使用
ZState appReducer(ZState state, action) {
  return ZState(
    // 将全局对象和action关联
    locale: LocaleReducer(state.locale, action),
    lang: LangReducer(state.lang, action),
    theme: ThemeReducer(state.theme, action),
    autoDNS: AutoDNSReducer(state.autoDNS, action),
    autoSocks5: AutoSocks5Reducer(state.autoSocks5, action),
    hostsMutex: HostsMutexReducer(state.hostsMutex, action),
  );
}
