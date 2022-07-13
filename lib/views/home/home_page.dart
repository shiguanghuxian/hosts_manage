import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/lang_store.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/home/bloc/home_bloc.dart';
import 'package:hosts_manage/views/home/widgets/home_edit.dart';
import 'package:hosts_manage/views/home/widgets/home_hosts_list.dart';
import 'package:macos_ui/macos_ui.dart';

// 首页
class HomePage extends StatefulWidget {
  const HomePage({
    Key key,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initHostsList();
  }

  final HomeBloc _homeBloc = HomeBloc();
  I18N lang;

  @override
  void dispose() {
    super.dispose();
  }

  _initHostsList() {
    if (!Platform.isWindows) {
      return;
    }
    // 等半秒钟，看一下是否启动错误
    Future.delayed(const Duration(milliseconds: 500), () async {
      _homeBloc.add(InitHostsListEvent(lang));
      StoreProvider.of<ZState>(context).dispatch(UpdateLangAction(lang));
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(builder: (context, store) {
      lang = StoreProvider.of<ZState>(context).state.lang;
      _homeBloc.add(InitHostsListEvent(lang));
      return BlocProvider(
        create: (context) {
          return _homeBloc;
        },
        child: MacosScaffold(
          toolBar: Platform.isWindows
              ? null
              : ToolBar(
                  title: Text(lang.get('home.title')),
                  centerTitle: true,
                  actions: [
                    ToolBarIconButton(
                      label: lang.get('public.open_main_menu'),
                      showLabel: false,
                      icon: const MacosIcon(
                        CupertinoIcons.sidebar_left,
                        color: MacosColors.systemGrayColor,
                      ),
                      onPressed: () {
                        MacosWindowScope.of(context).toggleSidebar();
                      },
                    ),
                  ],
                ),
          children: [
            ResizablePane(
              minWidth: 180,
              maxWidth: 260,
              startWidth: 200,
              resizableSide: ResizableSide.right,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: const HomeHostsList(),
                );
              },
            ),
            ContentArea(
              minWidth: 200,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(0),
                  controller: scrollController,
                  child: const HomeEdit(),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
