import 'dart:developer';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/golib/godart.dart';
import 'package:hosts_manage/golib/golib.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/common/common.dart';
import 'package:hosts_manage/views/socks5/bloc/socks5_bloc.dart';
import 'package:hosts_manage/views/socks5/widgets/socks5_action_button.dart';
import 'package:hosts_manage/views/socks5/widgets/socks5_cert.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as path;

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
          titleBar: Platform.isWindows
              ? null
              : TitleBar(
                  title: Text(lang.get('socks5.title')),
                  actions: [
                    MacosIconButton(
                      backgroundColor: MacosColors.transparent,
                      icon: const MacosIcon(
                        CupertinoIcons.sidebar_left,
                        color: MacosColors.systemGrayColor,
                      ),
                      onPressed: () {
                        MacosWindowScope.of(context).toggleSidebar();
                      },
                    ),
                    const SizedBox(width: 10),
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
                          Socks5Cert(),
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
