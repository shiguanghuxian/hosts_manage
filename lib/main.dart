import 'dart:developer';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/models/const.dart';
import 'package:hosts_manage/router/index.dart';
import 'package:hosts_manage/store/auto_dns.dart';
import 'package:hosts_manage/store/lang_store.dart';
import 'package:hosts_manage/store/locale_store.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/store/theme_store.dart';
import 'package:hosts_manage/theme/dark.dart';
import 'package:hosts_manage/theme/light.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/views/common/common.dart';
import 'package:hosts_manage/views/main/main_page.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:redux/redux.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initStore();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 语言异步加载问题
  I18N lang = I18N();
  // 适配macos_ui
  ThemeMode _mode = ThemeMode.system;

  final store = Store<ZState>(
    appReducer,
    initialState: ZState(locale: ModelConst.zhLang, lang: I18N()),
  );

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  // 初始化状态数据
  void initStore() async {
    final SharedPreferences prefs = await _prefs;
    String locale = prefs.getString("locale");
    I18N lang = I18N();
    if (locale == ModelConst.zhLang || locale == '' || locale == null) {
      lang.init(ModelConst.zhLang);
    } else {
      lang.init(ModelConst.enLang);
    }
    String theme = prefs.getString("theme");
    String autoDNS = prefs.getString("auto_dns");
    if (autoDNS == null || autoDNS == '') {
      autoDNS = 'false';
    }
    // 如果设置了软件启动运行dns代理则启动服务
    if (autoDNS == 'true') {
      startDnsProxy();
    }
    store.dispatch(UpdateLocaleAction(locale));
    store.dispatch(UpdateLangAction(lang));
    store.dispatch(UpdateThemeAction(theme));
    store.dispatch(UpdateAutoDNSAction(autoDNS));
    setState(() {
      lang = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('语言测试 ${lang.get("public.app_name")} -- ${_mode}');

    return StoreProvider(
      store: store,
      child: StoreBuilder<ZState>(builder: (context, store) {
        String theme = StoreProvider.of<ZState>(context).state.theme;
        // 主题
        if (theme == ModelConst.lightTheme) {
          _mode = ThemeMode.light;
        } else if (theme == ModelConst.darkTheme) {
          _mode = ThemeMode.dark;
        } else {
          _mode = ThemeMode.system;
        }
        log('应用启动主题 ${theme}');

        return MacosApp(
          title: lang.get('public.app_name'),
          debugShowCheckedModeBanner: false,
          theme: LightTheme,
          darkTheme: DarkTheme,
          themeMode: _mode,
          routes: routes,
          home: const MainPage(),
          builder: EasyLoading.init(),
        );
      }),
    );
  }
}
