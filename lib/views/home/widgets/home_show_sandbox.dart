import 'dart:developer';
import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hosts_manage/components/macos_alert_dialog.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/models/const.dart';
import 'package:hosts_manage/store/store.dart';
import 'package:hosts_manage/views/common/common.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path_provider/path_provider.dart';

/// 系统hosts内容变化
Future<bool> changeSystemHosts(BuildContext context) async {
  I18N lang = StoreProvider.of<ZState>(context).state.lang;
  // 更新hosts 或刷新dns服务
  await syncDataDnsProxy(); // dns代理
  int isOK = await saveHostsToSystem(context, lang); // 本地hosts文件
  // macos切是沙箱弹框提示,windows用户提示管理员打开应用
  if (isOK == 0) {
    Widget messageBody;
    String shellStr;
    if (ModelConst.sandboxEnable && Platform.isMacOS) {
      // 获取macos用户名，从下载目录获取
      Directory downloadsPath = await getDownloadsDirectory();
      List<String> downloadsPathArr = downloadsPath.path.split('/');
      log('用户名 ${downloadsPathArr[2]}');
      shellStr =
          "sudo /bin/chmod +a 'user:${downloadsPathArr[2]}:allow write' /etc/hosts";
      messageBody = Column(
        children: [
          Text(lang.get('home.copy_sandbox_message')),
          Text(shellStr),
        ],
      );
    } else if (Platform.isWindows) {
      messageBody = Text(lang.get('home.save_windows_err'));
    } else {
      EasyLoading.showError('Save hosts error');
      return false;
    }
    await showMacOSAlertDialog(
      context: context,
      builder: (BuildContext context) => MacOSAlertDialog(
        message: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: messageBody,
        ),
        primaryButton: PushButton(
          color: Colors.grey[350],
          buttonSize: ButtonSize.large,
          child: Text(lang.get('public.close')),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        secondaryButton: PushButton(
          color: Colors.green[400],
          buttonSize: ButtonSize.large,
          child: Text(lang.get('home.copy_sandbox_shell')),
          onPressed: () {
            FlutterClipboard.copy(shellStr).then((value) {
              log('copy结果');
              EasyLoading.showInfo(lang.get('public.copied'));
            }).onError((error, stackTrace) {
              if (error == null) {
                return;
              }
              EasyLoading.showError(error.toString());
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    // return isOK > 0;
  }
  return isOK == 1;
}
