import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/home/bloc/home_bloc.dart';
import 'package:macos_ui/macos_ui.dart';

// 已存在的hosts配置列表
class HomeHostsList extends StatefulWidget {
  HomeHostsList({
    Key key,
  }) : super(key: key);

  @override
  _HomeHostsListState createState() => _HomeHostsListState();
}

class _HomeHostsListState extends State<HomeHostsList> {
  @override
  void initState() {
    super.initState();
    _homeBloc = context.read<HomeBloc>();
  }

  HomeBloc _homeBloc;
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
        return BlocBuilder<HomeBloc, HomeState>(
          buildWhen: (previous, current) {
            return previous.changeHostList != current.changeHostList;
          },
          builder: (context, state) {
            // hosts配置列表
            List<Widget> hostsWidgets = [];
            for (var val in _homeBloc.state.hostsList) {
              Widget trailing;
              if (val.isBaseHosts != true) {
                if (state.editList) {
                  trailing = PushButton(
                    onPressed: () {
                      log('点击删除 ${val.name}');
                    },
                    color: Colors.red[400],
                    buttonSize: ButtonSize.small,
                    child: Text(lang.get('public.delete')),
                  );
                } else {
                  trailing = Transform.scale(
                    scale: 0.7,
                    child: MacosSwitch(
                      value: val.check,
                      onChanged: (value) {
                        log('点击 ${value} -- ${val.isBaseHosts}');
                        context
                            .read<HomeBloc>()
                            .add(ChangeSelectedHostsEvent(val.key, value));
                      },
                    ),
                  );
                }
              }
              hostsWidgets.add(ListTile(
                onTap: () {
                  // 单击切换 - 判断右侧内容不是否编辑
                  context.read<HomeBloc>().add(ChangeShowHostsEvent(val.key));
                },
                onLongPress: () {
                  // 长按弹出删除提示
                },
                title: Text(
                  val.name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    color: val.key == state.showHosts
                        ? MacosTheme.of(context).primaryColor
                        : MacosTheme.of(context).typography.title1.color,
                  ),
                ),
                trailing: val.isBaseHosts ? null : trailing,
              ));
            }
            return Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height - 65,
                  padding: const EdgeInsets.only(left: 8, right: 0),
                  child: Column(
                    children: hostsWidgets,
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          child: MacosIcon(
                            CupertinoIcons.add_circled,
                            color: MacosTheme.of(context).primaryColor,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            context
                                .read<HomeBloc>()
                                .add(ChangeEditListEvent(!state.editList));
                          },
                          child: Text(
                            state.editList ? lang.get('public.done') : lang.get('public.edit'),
                            style: TextStyle(
                              color: MacosTheme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
