import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/settings/widgets/settings_body.dart';
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

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(builder: (context, store) {
      I18N lang = StoreProvider.of<ZState>(context).state.lang;

      return MacosScaffold(
        toolBar: Platform.isWindows
            ? null
            : ToolBar(
                title: Text(lang.get('settings.title')),
                centerTitle: true,
                actions: [
                  ToolBarIconButton(
                    label: lang.get('public.open_main_menu'),
                    showLabel: false,
                    icon: const MacosIcon(
                      CupertinoIcons.sidebar_left,
                      color: MacosColors.systemGrayColor,
                    ),
                    onPressed: () {
                      MacosWindowScope.of(context).toggleSidebar();
                    },
                  ),
                ],
              ),
        children: [
          ContentArea(builder: (context, scrollController) {
            return const SettingsBody();
          }),
        ],
      );
    });
  }
}
