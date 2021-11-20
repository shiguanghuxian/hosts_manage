import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
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
  }

  final HomeBloc _homeBloc = HomeBloc();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(builder: (context, store) {
      I18N lang = StoreProvider.of<ZState>(context).state.lang;
      _homeBloc.add(InitHostsListEvent(lang));
      return BlocProvider(
        create: (context) {
          return _homeBloc;
        },
        child: MacosScaffold(
          titleBar: TitleBar(
            title: Text(lang.get('home.title')),
            actions: [
              MacosTooltip(
                message: lang.get('home.switch_main_menu_tooltip'),
                child: MacosIconButton(
                  backgroundColor: MacosColors.transparent,
                  icon: const MacosIcon(
                    CupertinoIcons.sidebar_left,
                    color: MacosColors.systemGrayColor,
                  ),
                  onPressed: () {
                    MacosWindowScope.of(context).toggleSidebar();
                  },
                ),
              ),
              const SizedBox(width: 10),
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
