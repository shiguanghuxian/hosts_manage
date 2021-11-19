import 'dart:developer';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/golib/godart.dart';
import 'package:hosts_manage/golib/golib.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/common/common.dart';
import 'package:hosts_manage/views/dns/bloc/dns_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:r_get_ip/r_get_ip.dart';

// 右下角操作按钮
class DnsActionButton extends StatefulWidget {
  const DnsActionButton({
    Key key,
  }) : super(key: key);

  @override
  _DnsActionButtonState createState() => _DnsActionButtonState();
}

class _DnsActionButtonState extends State<DnsActionButton> {
  @override
  void initState() {
    super.initState();
    _initIsRun();
    _dnsBloc = context.read<DNSBloc>();
    _getLocalIP();
  }

  DNSBloc _dnsBloc;
  I18N lang;
  bool isRun = false;

  @override
  void dispose() {
    super.dispose();
  }

  /// 获取一下dns启动状态
  void _initIsRun() {
    int isStart = getIsStart();
    log('当前启动状态 ${isStart}');
    setState(() {
      isRun = isStart == 1;
    });
  }

  /// 停止dns代理
  void _stopDNS() {
    stopDNS();
    setState(() {
      isRun = false;
    });
  }

  /// 启动dns代理
  void _startDns() async {
    // 设置hosts域名ip映射
    String hostsBody = await getAllHostsVal();
    setAddressBookDNS(GoString.fromString(hostsBody));
    // 设置公网上层dns服务
    String dnsServerBody = await readPublicDNSServer();
    setPublicDnsServerDNS(GoString.fromString(dnsServerBody));
    // 启动服务
    startDNS();
    setState(() {
      isRun = true;
    });
    _getLocalIP();
    // 等半秒钟，看一下是否启动错误
    Future.delayed(const Duration(milliseconds: 500), () async {
      Pointer<Int8> errPrt = getErr();

      String errStr = errPrt.cast<Utf8>().toDartString();
      log('启动错误信息 ${errStr}');
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
    _dnsBloc.add(ChangeLocalDnsAddrEvent("$ip:53"));
    log('内网ip ${ip}');
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ZState>(
      builder: (context, store) {
        lang = StoreProvider.of<ZState>(context).state.lang;
        return BlocBuilder<DNSBloc, DNSState>(
          buildWhen: (previous, current) {
            return previous.dnsServers != current.dnsServers;
          },
          builder: (context, state) {
            return InkWell(
              onTap: () {
                // 启动停止dns服务
                if (isRun) {
                  _stopDNS();
                  savePublicDNSServer(state.dnsServers);
                } else {
                  _startDns();
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
                    isRun ? lang.get('dns.stop') : lang.get('dns.start'),
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
