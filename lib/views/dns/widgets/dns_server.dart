import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
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
    _codeController = CodeController(
      text: '',
      language: python,
      theme: githubTheme,
    );
  }

  CodeController _codeController;
  I18N lang;

  @override
  void dispose() {
    _codeController.dispose();
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
              height: 260,
              child: CodeField(
                wrap: true,
                lineNumberStyle: LineNumberStyle(
                  background: Colors.grey[200],
                ),
                background: MacosTheme.of(context).brightness == Brightness.dark
                    ? Colors.grey[100]
                    : null,
                controller: _codeController,
                minLines: 15,
                textStyle: const TextStyle(fontFamily: 'SourceCode'),
              ),
            );
          },
        );
      },
    );
  }
}
