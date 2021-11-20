import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/common/common.dart';
import 'package:hosts_manage/views/dns/bloc/dns_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:highlight/languages/python.dart';

// dns 服务列表
class DnsServer extends StatefulWidget {
  const DnsServer({
    Key key,
  }) : super(key: key);

  @override
  _DnsServerState createState() => _DnsServerState();
}

class _DnsServerState extends State<DnsServer> {
  @override
  void initState() {
    super.initState();
    _dnsBloc = context.read<DNSBloc>();
    _codeController = CodeController(
      text: '',
      language: python,
      theme: githubTheme,
      onChange: _changeDnsServers,
    );
    _readPublicDNSServer();
  }

  DNSBloc _dnsBloc;
  CodeController _codeController;
  I18N lang;
  int serverLine = 0; // dns server配置行数，用于行数变化时保存到文件

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _changeDnsServers(String val) {
    _dnsBloc.add(ChangeDnsServersEvent(val));
    if (val != null && val != '') {
      int newServerLine = val.split('\n').length;
      if (newServerLine != serverLine) {
        savePublicDNSServer(val);
        serverLine = newServerLine;
      }
    }
  }

  // 读取已保存dns服务列表
  void _readPublicDNSServer() async {
    String str = await readPublicDNSServer();
    if (str == '') {
      str = '#启动时会保存配置到文件\n8.8.8.8\n';
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
        return BlocBuilder<DNSBloc, DNSState>(
          buildWhen: (previous, current) {
            return false;
          },
          builder: (context, state) {
            return SizedBox(
              width: 260,
              height: 200,
              child: MacosTooltip(
                message: lang.get('dns.server_tooltip'),
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
