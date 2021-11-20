/* 公共操作 */

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:ffi';

import 'package:cli_script/cli_script.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hosts_manage/golib/godart.dart';
import 'package:hosts_manage/golib/golib.dart';
import 'package:hosts_manage/models/hosts_info_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:ffi/ffi.dart';

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
    log('拼接的完整hosts文件内容 $hostsBody');
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

/// 保存hosts到系统hosts文件路径 EasyLoading.showError('Save failed');
saveHostsToSystem() async {
  try {
    String hostsBody = await getAllHostsVal();
    // 内容为空不保存
    if (hostsBody == null || hostsBody == '') {
      EasyLoading.showError('Error');
      return;
    }
    File hostsFile;
    if (Platform.isWindows) {
      hostsFile = File('C:\\Windows\\System32\\drivers\\etc\\hosts');
    } else {
      hostsFile = File('/etc/hosts');
    }
    // macos使用脚本获取权限写入
    if (Platform.isMacOS) {
      String rootPath = await getAppRootDirectory();
      String cachePath = path.join(rootPath, "hosts.cache");
      log('缓存hosts路径$cachePath');
      File cacheHostsFile = File(cachePath);
      cacheHostsFile.writeAsStringSync(hostsBody, flush: true);
      cachePath = cachePath.replaceAll(' ', '');
      String shellCode =
          '/usr/bin/osascript -e \'do shell script "cp $cachePath /private/etc/hosts" with administrator privileges\'';
      log('mac执行脚本 $shellCode');
      await run(shellCode, runInShell: true);
      // 删除缓存文件
      cacheHostsFile.deleteSync();
    } else {
      hostsFile.writeAsStringSync(hostsBody, flush: true);
    }
  } catch (e) {
    log('保存系统hosts文件错误:${e.toString()}');
    EasyLoading.showError('保存系统hosts文件错误');
  }
}
