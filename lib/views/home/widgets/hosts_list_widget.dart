import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/components/macos_alert_dialog.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/models/hosts_info_model.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/home/bloc/home_bloc.dart';
import 'package:macos_ui/macos_ui.dart';

// hosts配置列表中一个元素
class HostsListWidget extends StatefulWidget {
  const HostsListWidget({
    Key key,
    this.hostsInfoModel,
  }) : super(key: key);

  final HostsInfoModel hostsInfoModel;

  @override
  _HostsListWidgetState createState() => _HostsListWidgetState();
}

class _HostsListWidgetState extends State<HostsListWidget> {
  @override
  void initState() {
    super.initState();
    _homeBloc = context.read<HomeBloc>();
  }

  HomeBloc _homeBloc;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(
      builder: (context, store) {
        I18N lang = StoreProvider.of<ZState>(context).state.lang;
        return BlocBuilder<HomeBloc, HomeState>(
          buildWhen: (previous, current) {
            return previous.changeHostList != current.changeHostList;
          },
          builder: (context, state) {
            if (widget.hostsInfoModel == null) {
              return Container();
            }
            Widget trailing;
            if (widget.hostsInfoModel.isBaseHosts != true) {
              if (state.editList) {
                trailing = PushButton(
                  onPressed: () {
                    log('点击删除 ${widget.hostsInfoModel.name}');
                    showMacOSAlertDialog(
                      context: context,
                      builder: (BuildContext context) => MacOSAlertDialog(
                        title: Text(
                          lang.get('home.del_hosts_title'),
                          style: MacosTheme.of(context).typography.headline,
                        ),
                        message: Text(lang.get('home.del_hosts_message')),
                        primaryButton: PushButton(
                          color: Colors.grey[350],
                          buttonSize: ButtonSize.large,
                          child: Text(lang.get('public.cancel')),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        secondaryButton: PushButton(
                          color: Colors.red[400],
                          buttonSize: ButtonSize.large,
                          child: Text(lang.get('public.confirm')),
                          onPressed: () {
                            _homeBloc
                                .add(DelHostsEvent(widget.hostsInfoModel.key));
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    );
                  },
                  color: Colors.red[400],
                  buttonSize: ButtonSize.small,
                  isSecondary: true,
                  child: Text(
                    lang.get('public.delete'),
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                );
              } else {
                trailing = MacosTooltip(
                  message: lang.get('home.switch_hosts_tooltip'),
                  child: Transform.scale(
                    scale: 0.7,
                    child: MacosSwitch(
                      value: widget.hostsInfoModel.check,
                      onChanged: (value) {
                        log('点击 ${value} -- ${widget.hostsInfoModel.isBaseHosts}');
                        context.read<HomeBloc>().add(ChangeSelectedHostsEvent(
                            widget.hostsInfoModel.key, value));
                      },
                    ),
                  ),
                );
              }
            }
            return ListTile(
              onTap: () {
                // 单击切换 - 判断右侧内容不是否编辑
                context
                    .read<HomeBloc>()
                    .add(ChangeShowHostsEvent(widget.hostsInfoModel.key));
              },
              title: Text(
                widget.hostsInfoModel.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color: widget.hostsInfoModel.key == state.showHosts
                      ? MacosTheme.of(context).primaryColor
                      : MacosTheme.of(context).typography.title1.color,
                ),
              ),
              trailing:
                  widget.hostsInfoModel.isBaseHosts == true ? null : trailing,
            );
          },
        );
      },
    );
  }
}
