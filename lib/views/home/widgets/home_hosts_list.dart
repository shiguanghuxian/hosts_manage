import 'dart:async';
import 'dart:developer';
import 'dart:io';

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
import 'package:tray_manager/tray_manager.dart' as tray_manager;
import 'package:window_manager/window_manager.dart';

// 已存在的hosts配置列表
class HomeHostsList extends StatefulWidget {
  const HomeHostsList({
    Key key,
  }) : super(key: key);

  @override
  _HomeHostsListState createState() => _HomeHostsListState();
}

class _HomeHostsListState extends State<HomeHostsList>
    with tray_manager.TrayListener {
  @override
  void initState() {
    super.initState();
    tray_manager.trayManager.addListener(this);
    _homeBloc = context.read<HomeBloc>();
    //监听dns启动变化
    _subscription = eventBus
        .on<ChangeContextMenuDNSToHome>()
        .listen((ChangeContextMenuDNSToHome data) {
      _setContextMenu();
    });
    _subscription.resume();
    //监听socks5启动变化
    _subscriptionSocks5 = eventBus
        .on<ChangeContextMenuSocks5ToHome>()
        .listen((ChangeContextMenuSocks5ToHome data) {
      _setContextMenu();
    });
    _subscriptionSocks5.resume();
    // 初始化状态栏图标
    initSystemTray();
  }

  HomeBloc _homeBloc;
  I18N lang;
  bool isInitSystemTray = false; // 是否初始化了状态菜单
  StreamSubscription _subscription;
  StreamSubscription _subscriptionSocks5;
  bool hostsMutex = false;

  @override
  void dispose() {
    tray_manager.trayManager.removeListener(this);
    _subscription?.cancel();
    _subscriptionSocks5?.cancel();
    super.dispose();
  }

  // 状态栏菜单
  Future<void> initSystemTray() async {
    if (isInitSystemTray) {
      return;
    }
    isInitSystemTray = true;
    // 图标
    String path = 'lib/assets/images/icon.png';
    if (Platform.isWindows) {
      path = "lib/assets/images/icon.ico";
    }

    log('再次init菜单');
    // 图标、标题、提示
    await tray_manager.trayManager.setIcon(path);
    // tray_manager.trayManager.setTitle(lang.get('public.app_name'));
    tray_manager.trayManager.setToolTip(lang.get('home.icon_tooltip'));

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
    // 获取socks5代理启动情况
    bool socks5Run = socks5GetIsStart() == 1;
    String socks5RunLabel = '';
    if (socks5Run) {
      socks5RunLabel =
          lang.get('dns.stop') + lang.get('socks5.tray_socks5_proxy');
    } else {
      socks5RunLabel =
          lang.get('dns.start') + lang.get('socks5.tray_socks5_proxy');
    }

    // 菜单列表
    List<tray_manager.MenuItem> menuBase = [
      tray_manager.MenuItem.separator(),
      tray_manager.MenuItem(
        key: 'menu_dns',
        label: dnsLabel,
        onClick: (tray_manager.MenuItem it) async {
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
      tray_manager.MenuItem.separator(),
      tray_manager.MenuItem(
        key: 'menu_socks5',
        label: socks5RunLabel,
        onClick: (tray_manager.MenuItem it) async {
          log(socks5RunLabel);
          if (socks5Run) {
            socks5Stop();
          } else {
            await startSocks5Proxy();
          }

          // 等半秒钟
          Future.delayed(const Duration(milliseconds: 500), () async {
            _setContextMenu();
            // 通知菜单发生变化
            eventBus.fire(const ChangeContextMenuHomeToSocks5());
          });
        },
      ),
      tray_manager.MenuItem.separator(),
      tray_manager.MenuItem(
          key: 'menu_show_edit_hosts',
          label: lang.get('home.show_edit_hosts'),
          onClick: (tray_manager.MenuItem it) async {
            log(lang.get('home.show_edit_hosts'));
          }),
      tray_manager.MenuItem.separator(),
      tray_manager.MenuItem(
          key: 'menu_exit',
          label: lang.get('public.exit'),
          onClick: (tray_manager.MenuItem it) async {
            log('Exit');
            exit(0);
          }),
    ];

    final List<tray_manager.MenuItem> menus = [];
    for (HostsInfoModel item in _homeBloc.state.hostsList) {
      if (item.isBaseHosts == true) {
        continue;
      }
      menus.add(
        tray_manager.MenuItem(
          checked: item.check,
          label: item.name,
          onClick: (tray_manager.MenuItem it) {
            log('Show ${item.name}');
            context.read<HomeBloc>().add(ChangeSelectedHostsEvent(
                item.key, !item.check, hostsMutex, context));
          },
        ),
      );
    }
    menus.addAll(menuBase);
    await tray_manager.trayManager.setContextMenu(tray_manager.Menu(
      items: menus,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(
      builder: (context, store) {
        lang = StoreProvider.of<ZState>(context).state.lang;
        hostsMutex = StoreProvider.of<ZState>(context).state.hostsMutex;
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

  @override
  void onTrayIconMouseDown() {
    log('onTrayIconMouseDown');
    tray_manager.trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseUp() {
    log('onTrayIconMouseUp');
  }

  @override
  void onTrayIconRightMouseDown() {
    log('onTrayIconRightMouseDown');
    // trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    log('onTrayIconRightMouseUp');
    tray_manager.trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(tray_manager.MenuItem menuItem) {
    log(menuItem.toJson().toString());
    switch (menuItem.key) {
      case 'menu_show_edit_hosts':
        _showOrHideWindow();
        break;
      default:
    }
  }

  // 隐藏显示窗口
  _showOrHideWindow() async {
    bool isVisible = await windowManager.isVisible();
    log('当前显示状态 $isVisible');
    if (isVisible) {
      await windowManager.show();
      await windowManager.focus();
      return;
    }
    bool isMinimized = await windowManager.isMinimized();
    if (isMinimized) {
      await windowManager.restore();
      await windowManager.focus();
      return;
    }
    await windowManager.show();
    await windowManager.focus();
  }
}
