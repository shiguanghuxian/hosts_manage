import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
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
  bool isAuto = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(
      builder: (context, store) {
        lang = StoreProvider.of<ZState>(context).state.lang;
        return BlocBuilder<DNSBloc, DNSState>(
          buildWhen: (previous, current) {
            return false;
          },
          builder: (context, state) {
            return SizedBox(
                width: 260,
                child: Row(
                  children: [
                    MacosCheckbox(
                      value: isAuto,
                      semanticLabel: "11",
                      onChanged: (bool val) {
                        log('选中状态 ${val}');
                        setState(() {
                          isAuto = !isAuto;
                        });
                      },
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 3),
                      child: Text(lang.get('dns.auto_start_label')),
                    ),
                    
                  ],
                ));
          },
        );
      },
    );
  }
}
