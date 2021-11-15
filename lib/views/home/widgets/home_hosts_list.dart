import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/models/const.dart';
import 'package:hosts_manage/models/hosts_info_model.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/home/bloc/home_bloc.dart';
import 'package:hosts_manage/views/home/widgets/hosts_add_widget.dart';
import 'package:hosts_manage/views/home/widgets/hosts_list_widget.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:system_tray/system_tray.dart' as system_tray;

// 已存在的hosts配置列表
class HomeHostsList extends StatefulWidget {
  const HomeHostsList({
    Key key,
  }) : super(key: key);

  @override
  _HomeHostsListState createState() => _HomeHostsListState();
}

class _HomeHostsListState extends State<HomeHostsList> {
  @override
  void initState() {
    super.initState();
    _homeBloc = context.read<HomeBloc>();
  }

  HomeBloc _homeBloc;
  I18N lang;
  final system_tray.AppWindow _appWindow = system_tray.AppWindow();

  @override
  void dispose() {
    super.dispose();
  }

  // 状态栏菜单
  final system_tray.SystemTray _systemTray = system_tray.SystemTray();
  Future<void> initSystemTray() async {
    // 图标
    String path = 'lib/assets/images/icon.png';
    if (Platform.isWindows) {
      path = "lib/assets/images/icon.ico";
    }

    print('再次init菜单');

    // We first init the systray menu and then add the menu entries
    await _systemTray.initSystemTray(
      title: lang.get('public.app_name'),
      iconPath: path,
      toolTip: lang.get('home.icon_tooltip'),
      leftMouseShowMenu: true,
    );
    await _setContextMenu();
  }

  /// 更新菜单选项
  Future<void> _setContextMenu() async {
    // 菜单内容
    final List<system_tray.MenuItemBase> menuBase = [
      system_tray.MenuSeparator(),
      system_tray.MenuItem(
        label: lang.get('home.show_edit_hosts'),
        onClicked: () {
          log(lang.get('home.show_edit_hosts'));
          _appWindow.show();
        },
      ),
      system_tray.MenuSeparator(),
      system_tray.MenuItem(
        label: lang.get('public.exit'),
        onClicked: () {
          log('Exit');
          exit(0);
        },
      ),
    ];

    final List<system_tray.MenuItemBase> menu = [];
    for (HostsInfoModel item in _homeBloc.state.hostsList) {
      if (item.isBaseHosts) {
        continue;
      }
      menu.add(
        system_tray.MenuItem(
          state: item.check,
          label: item.name,
          onClicked: () {
            log('Show ${item.name}');
            context
                .read<HomeBloc>()
                .add(ChangeSelectedHostsEvent(item.key, !item.check));
          },
        ),
      );
    }
    menu.addAll(menuBase);
    await _systemTray.setContextMenu(menu);
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(
      builder: (context, store) {
        lang = StoreProvider.of<ZState>(context).state.lang;
        initSystemTray();
        return BlocBuilder<HomeBloc, HomeState>(
          buildWhen: (previous, current) {
            return previous.changeHostList != current.changeHostList;
          },
          builder: (context, state) {
            _setContextMenu();
            // hosts配置列表
            List<Widget> hostsWidgets = [];
            for (var val in _homeBloc.state.hostsList) {
              hostsWidgets.add(HostsListWidget(hostsInfoModel: val));
            }
            return Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height - 65,
                  padding: const EdgeInsets.only(left: 8, right: 0),
                  child: Column(
                    children: hostsWidgets,
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 30,
                  child: PushButton(
                    onPressed: () {
                      context.read<HomeBloc>().add(const ChangeShowHostsEvent(
                          ModelConst.systemShowHosts));
                    },
                    color: MacosTheme.of(context).primaryColor,
                    buttonSize: ButtonSize.large,
                    child: Text(
                      lang.get('home.show_system_hosts'),
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const HostsAddWidget(),
                        InkWell(
                          onTap: () {
                            context
                                .read<HomeBloc>()
                                .add(ChangeEditListEvent(!state.editList));
                          },
                          child: Text(
                            state.editList
                                ? lang.get('public.done')
                                : lang.get('public.edit'),
                            style: TextStyle(
                              color: MacosTheme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
