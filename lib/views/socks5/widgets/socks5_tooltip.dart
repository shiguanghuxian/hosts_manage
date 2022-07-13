import 'dart:io';

import 'package:cli_script/cli_script.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/socks5/bloc/socks5_bloc.dart';
import 'package:macos_ui/macos_ui.dart';

// 提示文本
class Socks5Tooltip extends StatefulWidget {
  const Socks5Tooltip({
    Key key,
  }) : super(key: key);

  @override
  _Socks5TooltipState createState() => _Socks5TooltipState();
}

class _Socks5TooltipState extends State<Socks5Tooltip> {
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
        return BlocBuilder<Socks5Bloc, Socks5State>(
          buildWhen: (previous, current) {
            return false;
          },
          builder: (context, state) {
            return RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: Platform.isMacOS ? lang.get('socks5.socks5_tooltip_macos') : lang.get('socks5.socks5_tooltip_windows'),
                  style: MacosTheme.of(context).typography.headline,
                ),
                WidgetSpan(
                  child: InkWell(
                    onTap: () {
                      if (Platform.isMacOS) {
                        run('open /System/Library/PreferencePanes/Network.prefPane');
                      }
                    },
                    child: Text(
                      Platform.isMacOS ? lang.get('socks5.open_preference') : '',
                      style: MacosTheme.of(context)
                          .typography
                          .headline
                          .copyWith(color: MacosTheme.of(context).primaryColor),
                    ),
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }
}
