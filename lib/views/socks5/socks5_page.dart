import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/socks5/bloc/socks5_bloc.dart';
import 'package:hosts_manage/views/socks5/widgets/socks5_action_button.dart';
import 'package:hosts_manage/views/socks5/widgets/socks5_auto_start.dart';
import 'package:hosts_manage/views/socks5/widgets/socks5_cert.dart';
import 'package:hosts_manage/views/socks5/widgets/socks5_hosts.dart';
import 'package:hosts_manage/views/socks5/widgets/socks5_local_ip.dart';
import 'package:hosts_manage/views/socks5/widgets/socks5_tooltip.dart';
import 'package:macos_ui/macos_ui.dart';

// 本地Socks5代理
class Socks5Page extends StatefulWidget {
  const Socks5Page({
    Key key,
  }) : super(key: key);

  @override
  _Socks5PageState createState() => _Socks5PageState();
}

class _Socks5PageState extends State<Socks5Page> {
  @override
  void initState() {
    super.initState();
  }

  final Socks5Bloc _socks5Bloc = Socks5Bloc();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(builder: (context, store) {
      I18N lang = StoreProvider.of<ZState>(context).state.lang;
      return BlocProvider(
        create: (context) {
          return _socks5Bloc;
        },
        child: MacosScaffold(
          toolBar: Platform.isWindows
              ? null
              : ToolBar(
                  title: Text(lang.get('socks5.title')),
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
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                controller: scrollController,
                child: Stack(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: Platform.isWindows
                          ? MediaQuery.of(context).size.height - 50
                          : MediaQuery.of(context).size.height - 90,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 400,
                            child: MacosListTile(
                              leading: SizedBox(
                                width: 120,
                                child: Text(
                                  lang.get('socks5.auto_start'),
                                  style:
                                      MacosTheme.of(context).typography.title3,
                                ),
                              ),
                              title: const Socks5AutoStart(),
                            ),
                          ),
                          const Divider(
                            height: 30,
                          ),
                          SizedBox(
                            width: 400,
                            child: MacosListTile(
                              leading: SizedBox(
                                width: 120,
                                child: Text(
                                  lang.get('socks5.ca_title'),
                                  style:
                                      MacosTheme.of(context).typography.title3,
                                ),
                              ),
                              title: const Socks5Cert(),
                            ),
                          ),
                          const Divider(
                            height: 30,
                          ),
                          SizedBox(
                            width: 400,
                            child: MacosListTile(
                              leading: SizedBox(
                                width: 120,
                                child: Text(
                                  lang.get('socks5.local_ip_title'),
                                  style:
                                      MacosTheme.of(context).typography.title3,
                                ),
                              ),
                              title: const Socks5LocalIp(),
                            ),
                          ),
                          const Divider(
                            height: 30,
                          ),
                          SizedBox(
                            width: 400,
                            child: MacosListTile(
                              leading: SizedBox(
                                width: 120,
                                child: Text(
                                  lang.get('socks5.hosts_title'),
                                  style:
                                      MacosTheme.of(context).typography.title3,
                                ),
                              ),
                              title: const Socks5Hosts(),
                            ),
                          ),
                          const Divider(
                            height: 30,
                          ),
                          const SizedBox(
                            width: 400,
                            child: Socks5Tooltip(),
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      right: 10,
                      bottom: 10,
                      child: Socks5ActionButton(),
                    )
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}
