import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/models/const.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/store/theme_store.dart';
import 'package:macos_ui/macos_ui.dart';

// 主题切换
class ThemePage extends StatefulWidget {
  const ThemePage({
    Key key,
  }) : super(key: key);

  @override
  _ThemePageState createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(builder: (context, store) {
      I18N lang = StoreProvider.of<ZState>(context).state.lang;
      return MacosScaffold(
        titleBar: TitleBar(
          title: Text(lang.get('theme.title')),
        ),
        children: [
          ContentArea(builder: (context, scrollController) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              controller: scrollController,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Light Theme'),
                      const SizedBox(width: 24),
                      MacosRadioButton<String>(
                        groupValue:
                            StoreProvider.of<ZState>(context).state.theme,
                        value: ModelConst.lightTheme,
                        onChanged: (value) {
                          StoreProvider.of<ZState>(context).dispatch(
                              UpdateThemeAction(ModelConst.lightTheme));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Dark Theme'),
                      const SizedBox(width: 26),
                      MacosRadioButton<String>(
                        groupValue:
                            StoreProvider.of<ZState>(context).state.theme,
                        value: ModelConst.darkTheme,
                        onChanged: (value) {
                          StoreProvider.of<ZState>(context).dispatch(
                              UpdateThemeAction(ModelConst.darkTheme));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
        // floatingActionButton: HomePublishBtn(),// 这里可放设置按钮
      );
    });
  }
}
