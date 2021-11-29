import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/common/common.dart';
import 'package:hosts_manage/views/socks5/bloc/socks5_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:highlight/languages/python.dart';

// 需代理加速域名列表
class Socks5Hosts extends StatefulWidget {
  const Socks5Hosts({
    Key key,
  }) : super(key: key);

  @override
  _Socks5HostsState createState() => _Socks5HostsState();
}

class _Socks5HostsState extends State<Socks5Hosts> {
  @override
  void initState() {
    super.initState();
    _socks5Bloc = context.read<Socks5Bloc>();
    _codeController = CodeController(
      text: '',
      language: python,
      theme: githubTheme,
      onChange: _changeSocks5Hostss,
    );
    _readSocks5Hosts();
  }

  Socks5Bloc _socks5Bloc;
  CodeController _codeController;
  I18N lang;
  int serverLine = 0; // 加速域名配置行数，用于行数变化时保存到文件

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _changeSocks5Hostss(String val) {
    _socks5Bloc.add(ChangeSocks5HostsEvent(val));
    if (val != null && val != '') {
      int newServerLine = val.split('\n').length;
      if (newServerLine != serverLine) {
        saveSocks5Hosts(val);
        serverLine = newServerLine;
      }
    }
  }

  // 读取socks5代理加速域名
  void _readSocks5Hosts() async {
    String str = await readSocks5Hosts();
    if (str == '') {
      str = '''# 加速域名
github.com
githubusercontent.com
githubassets.com
github.global.ssl.fastly.net
stackoverflow.com
stackexchange.com

''';
    }
    _codeController.text = str;
    if (str != null && str != '') {
      serverLine = str.split('\n').length;
    }
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
            return SizedBox(
              width: 260,
              height: 200,
              child: MacosTooltip(
                message: lang.get('socks5.hosts_tooltip'),
                child: CodeField(
                  wrap: true,
                  lineNumberStyle: LineNumberStyle(
                    background: Colors.grey[200],
                    width: 30,
                  ),
                  background:
                      MacosTheme.of(context).brightness == Brightness.dark
                          ? Colors.grey[100]
                          : null,
                  controller: _codeController,
                  minLines: 15,
                  textStyle: const TextStyle(fontFamily: 'SourceCode'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
