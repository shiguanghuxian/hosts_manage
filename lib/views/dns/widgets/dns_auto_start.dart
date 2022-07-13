import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/auto_dns.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/dns/bloc/dns_bloc.dart';
import 'package:macos_ui/macos_ui.dart';

// 软件启动开启dns
class DnsAutoStart extends StatefulWidget {
  const DnsAutoStart({
    Key key,
  }) : super(key: key);

  @override
  _DnsAutoStartState createState() => _DnsAutoStartState();
}

class _DnsAutoStartState extends State<DnsAutoStart> {
  @override
  void initState() {
    super.initState();
  }

  I18N lang;

  @override
  void dispose() {
    super.dispose();
  }

  /// 切换自动启动dns代理选项
  _changeAutoDNS() {
    String autoDNS = StoreProvider.of<ZState>(context).state.autoDNS;
    log('选中状态${autoDNS}');
    if (autoDNS == "true") {
      autoDNS = "false";
    } else {
      autoDNS = "true";
    }
    StoreProvider.of<ZState>(context).dispatch(UpdateAutoDNSAction(autoDNS));
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(
      builder: (context, store) {
        lang = StoreProvider.of<ZState>(context).state.lang;
        log('保存的是否自动启动 ${StoreProvider.of<ZState>(context).state.autoDNS}');
        return BlocBuilder<DNSBloc, DNSState>(
          buildWhen: (previous, current) {
            return false;
          },
          builder: (context, state) {
            return SizedBox(
              width: 260,
              child: InkWell(
                onTap: () {
                  _changeAutoDNS();
                },
                child: Row(
                  children: [
                    MacosCheckbox(
                      value: StoreProvider.of<ZState>(context).state.autoDNS ==
                          "true",
                      onChanged: (bool val) {
                        _changeAutoDNS();
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 3),
                      child: Text(lang.get('dns.auto_start_label')),
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
