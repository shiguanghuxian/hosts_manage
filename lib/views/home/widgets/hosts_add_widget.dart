import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/components/macos_alert_dialog.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/home/bloc/home_bloc.dart';
import 'package:macos_ui/macos_ui.dart';

// 添加hosts配置
class HostsAddWidget extends StatefulWidget {
  const HostsAddWidget({
    Key key,
  }) : super(key: key);

  @override
  _HostsAddWidgetState createState() => _HostsAddWidgetState();
}

class _HostsAddWidgetState extends State<HostsAddWidget> {
  @override
  void initState() {
    super.initState();
    _homeBloc = context.read<HomeBloc>();
  }

  HomeBloc _homeBloc;
  String hostsName = '';
  TextEditingController hostsNameController = TextEditingController();

  @override
  void dispose() {
    hostsNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(
      builder: (context, store) {
        I18N lang = StoreProvider.of<ZState>(context).state.lang;
        return BlocBuilder<HomeBloc, HomeState>(
          buildWhen: (previous, current) {
            return previous.hostsList != current.hostsList;
          },
          builder: (context, state) {
            return InkWell(
              onTap: () {
                hostsNameController.text = '';
                _homeBloc.add(const ChangeEditListEvent(false));
                showMacOSAlertDialog(
                  context: context,
                  builder: (BuildContext context) => MacOSAlertDialog(
                    title: Text(
                      lang.get('home.add_hosts_title'),
                      style: MacosTheme.of(context).typography.headline,
                    ),
                    message: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          Container(
                            child: MacosTextField(
                              controller: hostsNameController,
                              onChanged: (String val) {
                                setState(() {
                                  hostsName = val;
                                });
                              },
                              autofocus: true,
                              placeholder:
                                  lang.get('home.add_hosts_placeholder'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    primaryButton: PushButton(
                      color: Colors.grey[350],
                      buttonSize: ButtonSize.large,
                      child: Text(lang.get('public.cancel')),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    secondaryButton: PushButton(
                      color: Colors.green[400],
                      buttonSize: ButtonSize.large,
                      child: Text(lang.get('public.confirm')),
                      onPressed: () {
                        hostsName = hostsName.trim();
                        if (hostsName == '') {
                          EasyLoading.showError(lang.get('home.name_is_empty'));
                          return;
                        }
                        for (var item in state.hostsList) {
                          if (hostsName == item.name) {
                            EasyLoading.showError(lang.get('home.name_exists'));
                            return;
                          }
                        }
                        _homeBloc.add(AddHostsEvent(hostsName));
                        setState(() {
                          hostsName = '';
                        });
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
            );
          },
        );
      },
    );
  }
}
