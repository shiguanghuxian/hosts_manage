import 'dart:developer';
import 'dart:io';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/models/const.dart';
import 'package:hosts_manage/models/hosts_info_model.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/common/common.dart';
import 'package:hosts_manage/views/home/bloc/home_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:highlight/languages/python.dart';
import 'package:path_provider/path_provider.dart';

// 编辑一个hosts内容
class HomeEdit extends StatefulWidget {
  const HomeEdit({
    Key key,
  }) : super(key: key);

  @override
  _HomeEditState createState() => _HomeEditState();
}

class _HomeEditState extends State<HomeEdit> {
  @override
  void initState() {
    super.initState();
    _homeBloc = context.read<HomeBloc>();
    _codeController = CodeController(
      text: '',
      language: python,
      theme: githubTheme,
      onChange: _onChange,
    );
  }

  I18N lang;
  HomeBloc _homeBloc;
  CodeController _codeController;
  bool _showSave = true;
  String _content = ''; // 加载新hosts时的值
  String _newContent = ''; // 实时编辑hosts值

  @override
  void dispose() {
    _codeController?.dispose();
    super.dispose();
  }

  // 编辑内容变化时
  void _onChange(String val) {
    log('内容变化 ${val}');
    setState(() {
      _newContent = val;
    });
  }

  // 保存右侧内容
  _saveHostsContent() async {
    if (_homeBloc.state.showHosts == '' || _codeController.text == null) {
      return;
    }
    try {
      // 删除文件
      File hostsPath = await getHostsConfFile(_homeBloc.state.showHosts);
      log('保存文件路径 ${hostsPath.path}');
      hostsPath.writeAsStringSync(_codeController.text, flush: true);

      setState(() {
        _content = _newContent;
      });
      EasyLoading.showInfo(lang.get('home.save_hosts_ok'));
      // 更新hosts 或刷新dns服务
      // 当前编辑配置是打开时才重启
      bool isCheck = false;
      for (HostsInfoModel item in _homeBloc.state.hostsList) {
        if (item.key == _homeBloc.state.showHosts) {
          isCheck = item.check;
          break;
        }
      }
      if (isCheck == true) {
        await saveHostsToSystem(); // 本地hosts文件
        await syncDataDnsProxy(); // dns代理
      }
    } catch (e) {
      log('保存文件错误 ${e.toString()}');
      EasyLoading.showInfo(lang.get('home.save_hosts_err'));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(
      builder: (context, store) {
        lang = StoreProvider.of<ZState>(context).state.lang;
        return BlocListener<HomeBloc, HomeState>(
          listenWhen: (HomeState previous, HomeState current) {
            return previous.showHosts != current.showHosts ||
                previous.changeHostList != current.changeHostList;
          },
          listener: (BuildContext context, HomeState state) async {
            log('更新右侧编辑区内容 - ${state.showHosts}');
            File hostsPath;
            bool showSave = true;
            // 文件不存在
            if (state.showHosts == '') {
              showSave = false;
            } else if (state.showHosts.startsWith(ModelConst.systemShowHosts)) {
              // 显示系统hosts
              String sysHostsPath = '/etc/hosts';
              if (Platform.isWindows) {
                sysHostsPath = 'C:\\Windows\\System32\\drivers\\etc\\hosts';
              }
              hostsPath = File(sysHostsPath);
              showSave = false;
            } else {
              hostsPath = await getHostsConfFile(state.showHosts);

              if (!hostsPath.existsSync()) {
                EasyLoading.showError(lang.get('home.read_hosts_file_err'));
              }
            }
            setState(() {
              _showSave = showSave;
            });
            // 更新编辑器内容
            try {
              // 防止删除时读取不到文件
              if (state.showHosts != '') {
                _codeController.text = hostsPath.readAsStringSync();
              } else {
                _codeController.text = '';
              }
              _content = _codeController.text;
              _newContent = _content;
            } catch (e) {
              log('读取hosts配置内容错误 ${e.toString()}');
            }
          },
          child: Stack(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height - 53,
                child: CodeField(
                  wrap: true,
                  lineNumberStyle: LineNumberStyle(
                    background: Colors.grey[200],
                  ),
                  background:
                      MacosTheme.of(context).brightness == Brightness.dark
                          ? Colors.grey[100]
                          : null,
                  controller: _codeController,
                  minLines: 10,
                  textStyle: const TextStyle(fontFamily: 'SourceCode'),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: _showSave && _content != _newContent
                    ? InkWell(
                        onTap: () {
                          // 保存修改
                          _saveHostsContent();
                        },
                        child: Container(
                          width: 50,
                          height: 30,
                          decoration: BoxDecoration(
                            color: MacosTheme.of(context).primaryColor,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(15)),
                            boxShadow: [
                              BoxShadow(
                                  color: MacosTheme.of(context)
                                      .primaryColor
                                      .withAlpha(60),
                                  offset: const Offset(3.0, 3.0),
                                  blurRadius: 10.0,
                                  spreadRadius: 1.0)
                            ],
                          ),
                          child: Center(
                            child: Text(
                              lang.get('public.save'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(),
              ),
            ],
          ),
        );
      },
    );
  }
}
