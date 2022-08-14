/* 公共操作 */

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ffi';

import 'package:cli_script/cli_script.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hosts_manage/components/macos_alert_dialog.dart';
import 'package:hosts_manage/golib/godart.dart';
import 'package:hosts_manage/golib/golib.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/models/const.dart';
import 'package:hosts_manage/models/hosts_info_model.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:ffi/ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shell/shell.dart';

/// 获取存储跟目录
Future<String> getAppRootDirectory() async {
  Directory libDir = await getApplicationSupportDirectory();
  Directory rootDir =
      Directory(path.join(libDir.path, "shiguanghuxian", "HostsManage"));
  log('数据存储根目录 ${rootDir.path}');
  if (!rootDir.existsSync()) {
    await rootDir.create(recursive: true);
  }
  return rootDir.path;
}

/// 拼接完整hosts配置内容
Future<String> getAllHostsVal() async {
  try {
    File hostsFile = await getHostsJsonFile();
    String jsonStr = hostsFile.readAsStringSync();
    log('拼接完整hosts配置 ${jsonStr}');
    var obj = json.decode(jsonStr);
    List<HostsInfoModel> hostsList = [];
    if (obj != null) {
      hostsList = (obj as List).map((i) => HostsInfoModel.fromJson(i)).toList();
    }
    String hostsBody = '# Hosts Manage';
    for (HostsInfoModel item in hostsList) {
      if (item.check) {
        File hostsConfFile = await getHostsConfFile(item.key);
        String oneVal = hostsConfFile.readAsStringSync();
        if (oneVal.isEmpty) {
          continue;
        }
        hostsBody += "\n#${item.name}\n$oneVal";
      }
    }
    // log('拼接的完整hosts文件内容 $hostsBody');
    return hostsBody;
  } catch (e) {
    EasyLoading.showError('拼接hosts文件遇到异常 ${e.toString()}');
  }
  return '';
}

/// 同步代理信息到dns代理go进程
syncDataDnsProxy() async {
  log('同步代理信息到dns代理go进程');
  int isStart = getIsStart();
  if (isStart != 1) {
    return;
  }
  // 停止服务
  stopDNS();
  // 启动服务
  startDnsProxy();
}

/// 启动dns代理
startDnsProxy() async {
// 设置hosts域名ip映射
  String hostsBody = await getAllHostsVal();
  setAddressBookDNS(GoString.fromString(hostsBody));
  // 设置公网上层dns服务
  String dnsServerBody = await readPublicDNSServer();
  setPublicDnsServerDNS(GoString.fromString(dnsServerBody));

  // 启动服务
  startDNS();

  // 等半秒钟，看一下是否启动错误
  Future.delayed(const Duration(milliseconds: 500), () async {
    Pointer<Int8> errPrt = getErr();
    String errStr = errPrt.cast<Utf8>().toDartString();
    log('启动错误信息: ${errStr}');
    if (errStr != null && errStr != '') {
      EasyLoading.showError(errStr);
    }
  });
}

/// 启动socks5代理
startSocks5Proxy() async {
  // 读取socks5代理加速域名
  String socks5HostsBody = await readSocks5Hosts();
  socks5SetSpeedUpHosts(GoString.fromString(socks5HostsBody));

  // 启动服务
  socks5Start();

  // 等半秒钟，看一下是否启动错误
  Future.delayed(const Duration(milliseconds: 500), () async {
    Pointer<Int8> errPrt = socks5GetErr();
    String errStr = errPrt.cast<Utf8>().toDartString();
    log('启动错误信息: ${errStr}');
    if (errStr != null && errStr != '') {
      EasyLoading.showError(errStr);
    }
  });
}

/// 保存公网dns服务列表
savePublicDNSServer(String str) async {
  if (str.isEmpty) {
    str = '';
  }
  log('保存dns公网服务配置');
  String rootPath = await getAppRootDirectory();
  File dnsServersFile = File(path.join(rootPath, "dnsservers.json"));
  await dnsServersFile.writeAsString(str);
}

/// 读取公网服务器列表
Future<String> readPublicDNSServer() async {
  String rootPath = await getAppRootDirectory();
  File dnsServersFile = File(path.join(rootPath, "dnsservers.json"));
  if (!dnsServersFile.existsSync()) {
    return '';
  }
  return dnsServersFile.readAsStringSync();
}

/// 获取hosts配置json
Future<File> getHostsJsonFile() async {
  String rootPath = await getAppRootDirectory();
  log('hosts列表配置json路径 ${path.join(rootPath, "hosts.json")}');
  File hostsFile = File(path.join(rootPath, "hosts.json"));
  return hostsFile;
}

/// 获取一个hosts配置文件
Future<File> getHostsConfFile(String key) async {
  String hostsPath = await getHostsConfFilePath(key);
  return File(hostsPath);
}

/// hosts配置存储路径
Future<String> getHostsConfFilePath(String key) async {
  if (key.isEmpty) {
    EasyLoading.showError('hosts文件名为空');
    return null;
  }
  String rootPath = await getAppRootDirectory();
  Directory hostsConfDir = Directory(path.join(rootPath, "hostsfiles"));
  if (!hostsConfDir.existsSync()) {
    hostsConfDir.createSync();
  }
  return path.join(hostsConfDir.path, key + ".json");
}

/// 保存hosts到系统hosts文件路径
Future<int> saveHostsToSystem(BuildContext context, I18N lang) async {
  int saveOk = 0; // 是否保存成功
  try {
    String hostsBody = await getAllHostsVal();
    // 内容为空不保存
    if (hostsBody == null || hostsBody == '') {
      EasyLoading.showError('Save data is empty');
      return 1;
    }
    File hostsFile;
    String hostsFilePath = '/etc/hosts';
    if (Platform.isWindows) {
      hostsFilePath = 'C:\\Windows\\System32\\drivers\\etc\\hosts';
      hostsFile = File(hostsFilePath);
    } else {
      hostsFile = File(hostsFilePath); // /private/etc/hosts
    }
    // macos使用脚本获取权限写入
    if (Platform.isMacOS) {
      String rootPath = await getAppRootDirectory();
      String cachePath = path.join(rootPath, "hosts.cache");
      log('缓存hosts路径$cachePath');
      File cacheHostsFile = File(cachePath);
      cacheHostsFile.writeAsStringSync(hostsBody, flush: true);

      String shellCode = '';
      if (ModelConst.sandboxEnable) {
        // shellCode = "cp \"$cachePath\" /private/etc/hosts";
        hostsFile.writeAsStringSync(hostsBody, flush: true);
      } else {
        // 优先使用osascript方式如果失败，则使用密码方式
        log('系统版本 ${Platform.operatingSystemVersion}');

        // 查询osascript是否可操作
        SharedPreferences spf = await SharedPreferences.getInstance();
        bool osascriptFail = spf.getBool('osascript_fail');
        if (osascriptFail == null || !osascriptFail) {
          // 替换路径空格，防止cp命令语法错误
          cachePath = cachePath.replaceAll(' ', '');
          try {
            shellCode =
                '/usr/bin/osascript -e \'do shell script "cp $cachePath $hostsFilePath" with administrator privileges\'';
            log('mac执行osascript脚本 $shellCode');
            String shellVal = await output(shellCode, runInShell: true);
            log('执行osascript结果 $shellVal');
            saveOk = 1;
          } catch (e) {
            // 记录下osascript无法操作
            SharedPreferences.getInstance()
                .then((SharedPreferences prefs) async {
              bool ok = await prefs.setBool("osascript_fail", true);
              if (ok) {
                log('记录下osascript无法操作成功');
              }
            });
            EasyLoading.showToast(lang.get('home.save_macos_err'));
          }
        } else {
          String systemPassword = '';
          // 替换路径空格，防止cp命令语法错误
          cachePath = cachePath.replaceAll(' ', '');

          // var tmp = await getTemporaryDirectory();
          // log('缓存目录$tmp');
          // File cacheHostsFile1 = File(path.join('/tmp', "abd.hosts"));
          // cacheHostsFile1.writeAsStringSync(hostsBody, flush: true);

          await showMacOSAlertDialog(
            context: context,
            builder: (BuildContext context) => MacOSAlertDialog(
              title: Text(
                lang.get('home.system_password_title'),
                style: MacosTheme.of(context).typography.headline,
              ),
              message: Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    SizedBox(
                      child: MacosTextField(
                        obscureText: true,
                        onChanged: (String val) {
                          systemPassword = val;
                        },
                        autofocus: true,
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
                  saveOk = 2;
                  Navigator.of(context).pop();
                },
              ),
              secondaryButton: PushButton(
                color: Colors.green[400],
                buttonSize: ButtonSize.large,
                child: Text(lang.get('public.confirm')),
                onPressed: () async {
                  if (systemPassword == null || systemPassword == '') {
                    EasyLoading.showToast(
                        lang.get('home.system_password_is_empty'));
                    return;
                  }
                  // 拼接shell脚本
                  List<String> cmds = [
                    "#!/bin/sh",
                    "echo '$systemPassword' | sudo -S chmod 777 $hostsFilePath",
                    "cat \"$cachePath\" > $hostsFilePath",
                    "echo '$systemPassword' | sudo -S chmod 644 $hostsFilePath"
                  ];
                  String shellPath = path.join(rootPath, "hosts.sh");
                  File shellFile = File(shellPath);
                  shellFile.writeAsStringSync(cmds.join("\n"), flush: true);
                  // 执行新写入的shell
                  var shell = Shell();
                  var shellVal = await shell.startAndReadAsString('/bin/bash',
                      arguments: [shellFile.path]);
                  log('执行shell结果 $shellVal');
                  saveOk = shellVal == '' ? 1 : 0;
                  // 删除脚本
                  shellFile.delete();

                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        }
      }
      // 删除缓存文件
      cacheHostsFile.deleteSync();
    } else {
      hostsFile.writeAsStringSync(hostsBody, flush: true);
    }
  } catch (e) {
    log('保存系统hosts文件错误 ${e.toString()}');
    return 0;
  }
  return saveOk;
}

/// 保存socks5代理加速域名
saveSocks5Hosts(String str) async {
  if (str.isEmpty) {
    str = '';
  }
  log('保存socks5代理加速域名');
  String rootPath = await getAppRootDirectory();
  File socks5HostsFile = File(path.join(rootPath, "socks5hosts.json"));
  await socks5HostsFile.writeAsString(str);
}

/// 读取socks5代理加速域名
Future<String> readSocks5Hosts() async {
  String rootPath = await getAppRootDirectory();
  File socks5HostsFile = File(path.join(rootPath, "socks5hosts.json"));
  if (!socks5HostsFile.existsSync()) {
    return '';
  }
  return socks5HostsFile.readAsStringSync();
}
