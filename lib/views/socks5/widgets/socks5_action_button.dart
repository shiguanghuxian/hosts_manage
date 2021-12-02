import 'dart:async';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/event_manage/event_manage.dart';
import 'package:hosts_manage/golib/godart.dart';
import 'package:hosts_manage/golib/golib.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/common/common.dart';
import 'package:hosts_manage/views/socks5/bloc/socks5_bloc.dart';
import 'package:r_get_ip/r_get_ip.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as path;

// 右下角操作按钮
class Socks5ActionButton extends StatefulWidget {
  const Socks5ActionButton({
    Key key,
  }) : super(key: key);

  @override
  _Socks5ActionButtonState createState() => _Socks5ActionButtonState();
}

class _Socks5ActionButtonState extends State<Socks5ActionButton> {
  @override
  void initState() {
    super.initState();
    _initIsRun();
    _socks5Bloc = context.read<Socks5Bloc>();
    _getLocalIP();
    //监听dns启动变化
    _subscription = eventBus
        .on<ChangeContextMenuHomeToSocks5>()
        .listen((ChangeContextMenuHomeToSocks5 data) {
      _initIsRun();
    });
    _subscription.resume();
  }

  Socks5Bloc _socks5Bloc;
  I18N lang;
  bool isRun = false;
  StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// 获取一下socks5启动状态
  void _initIsRun() {
    int isStart = socks5GetIsStart();
    log('当前启动状态 ${isStart}');
    setState(() {
      isRun = isStart == 1;
    });
  }

  /// 停止socks5代理
  void _stopSocks5() {
    socks5Stop();
    setState(() {
      isRun = false;
    });
  }

  /// 启动socks5代理
  void _startSocks5() async {
    int isStart = socks5GetIsStart();
    if (isStart == 1) {
      setState(() {
        isRun = isStart == 1;
      });
      return;
    }

    // 设置根路径
    _socks5SetCertPath();

    // 读取socks5代理加速域名
    String socks5HostsBody = await readSocks5Hosts();
    socks5SetSpeedUpHosts(GoString.fromString(socks5HostsBody));

    // 启动服务
    socks5Start();
    setState(() {
      isRun = true;
    });
    _getLocalIP();
    // 等半秒钟，看一下是否启动错误
    Future.delayed(const Duration(milliseconds: 500), () async {
      // 通知菜单发生变化
      eventBus.fire(const ChangeContextMenuSocks5ToHome());
      // 获取go socks5启动错误信息
      Pointer<Int8> errPrt = socks5GetErr();
      String errStr = errPrt.cast<Utf8>().toDartString();
      log('启动错误信息: ${errStr}');
      if (errStr != null && errStr != '') {
        EasyLoading.showError(errStr);
        // 重新获取一下启动状态
        _initIsRun();
      }
    });
  }

  /// 获取本机IP
  _getLocalIP() async {
    String ip = await RGetIp.internalIP;
    _socks5Bloc.add(ChangeLocalSocks5AddrEvent("$ip:10109"));
    log('内网ip ${ip}');
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
            return InkWell(
              onTap: () {
                // 启动停止socks5服务
                if (isRun) {
                  _stopSocks5();
                } else {
                  _startSocks5();
                }
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isRun
                      ? Colors.red[400]
                      : MacosTheme.of(context).primaryColor,
                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                  boxShadow: [
                    BoxShadow(
                        color: isRun
                            ? Colors.red[400].withAlpha(60)
                            : MacosTheme.of(context).primaryColor.withAlpha(60),
                        offset: const Offset(3.0, 3.0),
                        blurRadius: 10.0,
                        spreadRadius: 1.0)
                  ],
                ),
                child: Center(
                  child: Text(
                    isRun ? lang.get('socks5.stop') : lang.get('socks5.start'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
