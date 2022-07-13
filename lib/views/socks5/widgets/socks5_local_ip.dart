import 'dart:developer';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/socks5/bloc/socks5_bloc.dart';
import 'package:macos_ui/macos_ui.dart';

// 本机IP
class Socks5LocalIp extends StatefulWidget {
  const Socks5LocalIp({
    Key key,
  }) : super(key: key);

  @override
  _Socks5LocalIpState createState() => _Socks5LocalIpState();
}

class _Socks5LocalIpState extends State<Socks5LocalIp> {
  @override
  void initState() {
    super.initState();
  }

  I18N lang;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(
      builder: (context, store) {
        lang = StoreProvider.of<ZState>(context).state.lang;
        return BlocBuilder<Socks5Bloc, Socks5State>(
          buildWhen: (previous, current) {
            return previous.localSocks5Addr != current.localSocks5Addr;
          },
          builder: (context, state) {
            return SizedBox(
              width: 260,
              child: Row(
                children: [
                  Text(state.localSocks5Addr),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: MacosTooltip(
                      message: lang.get('socks5.local_ip_copy_tooltip'),
                      child: InkWell(
                        onTap: () {
                          FlutterClipboard.copy(state.localSocks5Addr)
                              .then((value) {
                            log('copy结果');
                            EasyLoading.showInfo(lang.get('public.copied'));
                          }).onError((error, stackTrace) {
                            if (error == null) {
                              return;
                            }
                            EasyLoading.showError(error.toString());
                          });
                        },
                        child: const MacosIcon(
                          Icons.copy_sharp,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
