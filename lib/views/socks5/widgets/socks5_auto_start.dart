import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/auto_socks5.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/socks5/bloc/socks5_bloc.dart';
import 'package:macos_ui/macos_ui.dart';

// 软件启动开启socks5
class Socks5AutoStart extends StatefulWidget {
  const Socks5AutoStart({
    Key key,
  }) : super(key: key);

  @override
  _Socks5AutoStartState createState() => _Socks5AutoStartState();
}

class _Socks5AutoStartState extends State<Socks5AutoStart> {
  @override
  void initState() {
    super.initState();
  }

  I18N lang;

  @override
  void dispose() {
    super.dispose();
  }

  /// 切换自动启动socks5代理选项
  _changeAutoSocks5() {
    String autoSocks5 = StoreProvider.of<ZState>(context).state.autoSocks5;
    log('选中状态${autoSocks5}');
    if (autoSocks5 == "true") {
      autoSocks5 = "false";
    } else {
      autoSocks5 = "true";
    }
    StoreProvider.of<ZState>(context)
        .dispatch(UpdateAutoSocks5Action(autoSocks5));
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(
      builder: (context, store) {
        lang = StoreProvider.of<ZState>(context).state.lang;
        log('保存的是否自动启动 ${StoreProvider.of<ZState>(context).state.autoSocks5}');
        return BlocBuilder<Socks5Bloc, Socks5State>(
          buildWhen: (previous, current) {
            return false;
          },
          builder: (context, state) {
            return SizedBox(
              width: 260,
              child: InkWell(
                onTap: () {
                  _changeAutoSocks5();
                },
                child: Row(
                  children: [
                    MacosCheckbox(
                      value:
                          StoreProvider.of<ZState>(context).state.autoSocks5 ==
                              "true",
                      onChanged: (bool val) {
                        _changeAutoSocks5();
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 3),
                      child: Text(lang.get('socks5.auto_start_label')),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
