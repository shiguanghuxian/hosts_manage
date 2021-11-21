import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/event_manage/event_manage.dart';
import 'package:hosts_manage/golib/golib.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/models/const.dart';
import 'package:hosts_manage/models/hosts_info_model.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/common/common.dart';
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
    //监听dns启动变化
    _subscription = eventBus
        .on<ChangeContextMenuDNSToHome>()
        .listen((ChangeContextMenuDNSToHome data) {
      _setContextMenu();
    });
    _subscription.resume();
  }

  HomeBloc _homeBloc;
  I18N lang;
  final system_tray.AppWindow _appWindow = system_tray.AppWindow();
  bool isInitSystemTray = false; // 是否初始化了状态菜单
  StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
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
    // 获取dns代理启动情况
    bool dnsRun = getIsStart() == 1;
    String dnsLabel = '';
    if (dnsRun) {
      dnsLabel = lang.get('dns.stop') + lang.get('dns.tray_dns_proxy');
    } else {
      dnsLabel = lang.get('dns.start') + lang.get('dns.tray_dns_proxy');
    }
    // 菜单内容
    final List<system_tray.MenuItemBase> menuBase = [
      system_tray.MenuSeparator(),
      system_tray.MenuItem(
        label: dnsLabel,
        onClicked: () async {
          log(dnsLabel);
          if (dnsRun) {
            stopDNS();
          } else {
            await startDnsProxy();
          }

          // 等半秒钟
          Future.delayed(const Duration(milliseconds: 500), () async {
            _setContextMenu();
            // 通知菜单发生变化
            eventBus.fire(const ChangeContextMenuHomeToDNS());
          });
        },
      ),
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
      if (item.isBaseHosts == true) {
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
                .add(ChangeSelectedHostsEvent(item.key, !item.check, context));
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
        // 防止重复初始化顶部菜单
        if (!isInitSystemTray) {
          initSystemTray();
          isInitSystemTray = true;
        }

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
                  height: Platform.isWindows
                      ? MediaQuery.of(context).size.height - 10
                      : MediaQuery.of(context).size.height - 65,
                  padding: const EdgeInsets.only(left: 8, right: 0),
                  child: Column(
                    children: hostsWidgets,
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 30,
                  child: MacosTooltip(
                    message: lang.get('home.show_hosts_tooltip'),
                    child: PushButton(
                      onPressed: () {
                        context.read<HomeBloc>().add(ChangeShowHostsEvent(
                            ModelConst.systemShowHosts +
                                DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString()));
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
                        MacosTooltip(
                          message: lang.get('home.add_btn_tooltip'),
                          child: const HostsAddWidget(),
                        ),
                        MacosTooltip(
                          message: lang.get('home.edit_tooltip'),
                          child: InkWell(
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
