import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/models/const.dart';
import 'package:hosts_manage/store/lang_store.dart';
import 'package:hosts_manage/store/locale_store.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/store/theme_store.dart';
import 'package:macos_ui/macos_ui.dart';

// 设置
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    Key key,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 切换语言
  void _changeLang(String locale) {
    StoreProvider.of<ZState>(context).dispatch(UpdateLocaleAction(locale));
    I18N lang = I18N();
    lang.init(locale);
    StoreProvider.of<ZState>(context).dispatch(UpdateLangAction(lang));
  }

  /// 切换主题
  void _changeTheme(String theme) {
    StoreProvider.of<ZState>(context).dispatch(UpdateThemeAction(theme));
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(builder: (context, store) {
      I18N lang = StoreProvider.of<ZState>(context).state.lang;
      ZState zxState = StoreProvider.of<ZState>(context).state;
      return MacosScaffold(
        titleBar: TitleBar(
          title: Text(lang.get('settings.title')),
        ),
        children: [
          ContentArea(builder: (context, scrollController) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              controller: scrollController,
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 200,
                      child: MacosListTile(
                        leading: SizedBox(
                          width: 60,
                          child: Text(
                            lang.get('settings.theme_title'),
                            style: MacosTheme.of(context).typography.title3,
                          ),
                        ),
                        title: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                _changeTheme(ModelConst.autoTheme);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MacosRadioButton<String>(
                                    groupValue: ModelConst.autoTheme,
                                    value: zxState.theme,
                                    onChanged: (value) {
                                      _changeTheme(ModelConst.autoTheme);
                                    },
                                  ),
                                  const SizedBox(width: 5),
                                  SizedBox(
                                    width: 100,
                                    child:
                                        Text(lang.get('settings.theme_auto')),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                _changeTheme(ModelConst.lightTheme);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MacosRadioButton<String>(
                                    groupValue: ModelConst.lightTheme,
                                    value: zxState.theme,
                                    onChanged: (value) {
                                      _changeTheme(ModelConst.lightTheme);
                                    },
                                  ),
                                  const SizedBox(width: 5),
                                  SizedBox(
                                    width: 100,
                                    child:
                                        Text(lang.get('settings.theme_light')),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                _changeTheme(ModelConst.darkTheme);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MacosRadioButton<String>(
                                    groupValue: ModelConst.darkTheme,
                                    value: zxState.theme,
                                    onChanged: (value) {
                                      _changeTheme(ModelConst.darkTheme);
                                    },
                                  ),
                                  const SizedBox(width: 5),
                                  SizedBox(
                                    width: 100,
                                    child:
                                        Text(lang.get('settings.theme_dark')),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(
                      height: 30,
                    ),
                    SizedBox(
                      width: 200,
                      child: MacosListTile(
                        leading: SizedBox(
                          width: 60,
                          child: Text(
                            lang.get('settings.lang_title'),
                            style: MacosTheme.of(context).typography.title3,
                          ),
                        ),
                        title: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                _changeLang(ModelConst.zhLang);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MacosRadioButton<String>(
                                    groupValue: ModelConst.zhLang,
                                    value: zxState.locale,
                                    onChanged: (value) {
                                      _changeLang(ModelConst.zhLang);
                                    },
                                  ),
                                  const SizedBox(width: 5),
                                  const SizedBox(
                                    width: 100,
                                    child: Text('中文'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                _changeLang(ModelConst.enLang);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  MacosRadioButton<String>(
                                    groupValue: ModelConst.enLang,
                                    value: zxState.locale,
                                    onChanged: (value) {
                                      _changeLang(ModelConst.enLang);
                                    },
                                  ),
                                  const SizedBox(width: 5),
                                  const SizedBox(
                                    width: 100,
                                    child: Text('English'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );
    });
  }
}