import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/dns/bloc/dns_bloc.dart';
import 'package:macos_ui/macos_ui.dart';

// 本地DNS代理
class DNSPage extends StatefulWidget {
  const DNSPage({
    Key key,
  }) : super(key: key);

  @override
  _DNSPageState createState() => _DNSPageState();
}

class _DNSPageState extends State<DNSPage> {
  @override
  void initState() {
    super.initState();
  }

  final DNSBloc _dnsBloc = DNSBloc();

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
          return _dnsBloc;
        },
        child: MacosScaffold(
          titleBar: TitleBar(
            title: Text(lang.get('dns.title')),
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
                child: Center(
                  child: Text('DNS'),
                ),
              );
            }),
          ],
          // floatingActionButton: HomePublishBtn(),// 这里可放dns启动。。。
        ),
      );
    });
  }
}
