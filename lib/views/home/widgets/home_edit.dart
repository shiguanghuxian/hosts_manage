import 'dart:developer';
import 'dart:io';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/home/bloc/home_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:highlight/languages/python.dart';
import 'package:path_provider/path_provider.dart';

// 编辑一个hosts内容
class HomeEdit extends StatefulWidget {
  HomeEdit({
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
    );
  }

  HomeBloc _homeBloc;
  CodeController _codeController;

  @override
  void dispose() {
    _codeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(
      builder: (context, store) {
        I18N lang = StoreProvider.of<ZState>(context).state.lang;
        return BlocListener<HomeBloc, HomeState>(
          listenWhen: (HomeState previous, HomeState current) {
            return previous.showHosts != current.showHosts;
          },
          listener: (BuildContext context, HomeState state) async {
            log('更新右侧编辑区内容 - ${state.showHosts}');
            Directory libDir = await getLibraryDirectory();
            File hostsPath =
                File(libDir.path + "/" + state.showHosts + ".json");
            if (!hostsPath.existsSync()) {
              EasyLoading.showError('读取对应hosts配置内容错误');
            }
            // 更新编辑器内容
            _codeController.text = hostsPath.readAsStringSync();
          },
          child: Stack(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height - 65,
                child: CodeField(
                  wrap: true,
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
                child: Container(
                  width: 50,
                  height: 30,
                  decoration: BoxDecoration(
                    color: MacosTheme.of(context).primaryColor,
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    boxShadow: [
                      BoxShadow(
                          color:
                              MacosTheme.of(context).primaryColor.withAlpha(60),
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
              ),
            ],
          ),
        );
      },
    );
  }
}
