import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:cli_script/cli_script.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/components/macos_alert_dialog.dart';
import 'package:hosts_manage/golib/godart.dart';
import 'package:hosts_manage/golib/golib.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/common/common.dart';
import 'package:hosts_manage/views/socks5/bloc/socks5_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as path;

// 证书生成
class Socks5Cert extends StatefulWidget {
  const Socks5Cert({
    Key key,
  }) : super(key: key);

  @override
  _Socks5CertState createState() => _Socks5CertState();
}

class _Socks5CertState extends State<Socks5Cert> {
  @override
  void initState() {
    super.initState();
    _socks5Bloc = context.read<Socks5Bloc>();
    _socks5SetCertPath();
    _initCaExist();
  }

  Socks5Bloc _socks5Bloc;
  I18N lang;
  bool caExist = false; // 是否已经生成证书

  @override
  void dispose() {
    super.dispose();
  }

  // 获取证书根路径
  Future<String> _getCaRootPath() async {
    String rootDir = await getAppRootDirectory();
    Directory caRootDir = Directory(path.join(rootDir, "ca"));
    if (!caRootDir.existsSync()) {
      await caRootDir.create(recursive: true);
    }
    return caRootDir.path;
  }

  // 设置证书跟路径
  void _socks5SetCertPath() async {
    String caRootDir = await _getCaRootPath();
    log('数据存储根目录 $caRootDir');
    socks5SetCertPath(GoString.fromString(caRootDir));
  }

  // 获取证书是否生成
  void _initCaExist() async {
    String caRootDir = await _getCaRootPath();
    File caPemFile = File(path.join(caRootDir, "cert.pem"));
    if (caPemFile.existsSync()) {
      caExist = true;
    } else {
      caExist = false;
    }
    setState(() {
      caExist = caExist;
    });
  }

  // 生成证书
  void _genCaCert() {
    if (caExist) {
      return;
    }
    Pointer<Int8> genErr = socks5GenCaCert();
    String errStr = genErr.cast<Utf8>().toDartString();
    log('生成证书错误信息: ${errStr}');
    _initCaExist();
    if (errStr != null && errStr != '') {
      EasyLoading.showError(errStr);
    } else {
      showMacOSAlertDialog(
        context: context,
        builder: (BuildContext context) => MacOSAlertDialog(
          message: Text(lang.get('socks5.create_ca_message')),
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
            child: Text(lang.get('socks5.open_ca_path_btn')),
            onPressed: () {
              Navigator.of(context).pop();
              _openCaCert();
            },
          ),
        ),
      );
    }
  }

  // 打开证书目录
  void _openCaCert() async {
    if (!caExist) {
      return;
    }
    String caRootDir = await _getCaRootPath();
    if (Platform.isMacOS) {
      run('open "$caRootDir"');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(
      builder: (context, store) {
        lang = StoreProvider.of<ZState>(context).state.lang;
        return BlocBuilder<Socks5Bloc, Socks5State>(
          buildWhen: (previous, current) {
            return false;
          },
          builder: (context, state) {
            return SizedBox(
              child: PushButton(
                child: caExist
                    ? Text(lang.get('socks5.open_ca_path'))
                    : Text(lang.get('socks5.create_ca')),
                buttonSize: ButtonSize.large,
                onPressed: () {
                  if (caExist) {
                    _openCaCert();
                  } else {
                    _genCaCert();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
