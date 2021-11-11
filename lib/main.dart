import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/models/const.dart';
import 'package:hosts_manage/router/index.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/theme/dark.dart';
import 'package:hosts_manage/theme/light.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/views/main/main_page.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:redux/redux.dart';

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
    initLang();
  }

  // 语言异步加载问题
  I18N lang = I18N();
  // 适配macos_ui
  ThemeMode _mode = ThemeMode.dark;

  void initLang() async {
    await lang.init('zh');
    setState(() {
      lang = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Store<ZState>(
      appReducer,
      initialState: ZState(locale: 'zh', lang: lang),
    );

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
          _mode = ThemeMode.light;
        }

        return MacosApp(
          title: lang.get('public.app_name'),
          debugShowCheckedModeBanner: false,
          theme: LightTheme,
          darkTheme: DarkTheme,
          themeMode: _mode,
          routes: routes,
          home: MainPage(),
          builder: EasyLoading.init(),
        );
      }),
    );
  }
}
