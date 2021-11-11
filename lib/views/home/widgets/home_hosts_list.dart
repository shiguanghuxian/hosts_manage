import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/components/macos_alert_dialog.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/home/bloc/home_bloc.dart';
import 'package:hosts_manage/views/home/widgets/hosts_list_widget.dart';
import 'package:macos_ui/macos_ui.dart';

// 已存在的hosts配置列表
class HomeHostsList extends StatefulWidget {
  const HomeHostsList({
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
              hostsWidgets.add(HostsListWidget(hostsInfoModel: val));
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
                          onTap: () {
                            showMacOSAlertDialog(
                              context: context,
                              builder: (_) => MacOSAlertDialog(
                                title: Text(
                                  'Alert Dialog with Primary Action',
                                  style: MacosTheme.of(context)
                                      .typography
                                      .headline,
                                ),
                                message: Text(
                                  'This is an alert dialog with a primary action and no secondary action',
                                  textAlign: TextAlign.center,
                                  style: MacosTheme.of(context)
                                      .typography
                                      .headline,
                                ),
                                primaryButton: PushButton(
                                  buttonSize: ButtonSize.large,
                                  child: Text('Primary'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                secondaryButton: PushButton(
                                  buttonSize: ButtonSize.large,
                                  child: Text('Primary'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            );
                          },
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
                            state.editList
                                ? lang.get('public.done')
                                : lang.get('public.edit'),
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
