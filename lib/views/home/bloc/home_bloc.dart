import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/models/hosts_info_model.dart';
import 'package:hosts_manage/views/common/common.dart';
import 'package:hosts_manage/views/home/widgets/home_show_sandbox.dart';
import 'package:path_provider/path_provider.dart';

part "home_event.dart";
part "home_state.dart";

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState());

  @override
  Stream<HomeState> mapEventToState(HomeEvent event) async* {
    if (event is ChangeSelectedHostsEvent) {
      yield await _mapChangeSelectedHosts(event, state);
    } else if (event is InitHostsListEvent) {
      yield await _mapInitHostsList(event, state);
    } else if (event is ChangeShowHostsEvent) {
      yield _mapChangeShowHosts(event, state);
    } else if (event is ChangeEditListEvent) {
      yield _mapChangeEditList(event, state);
    } else if (event is AddHostsEvent) {
      yield await _mapAddHosts(event, state);
    } else if (event is DelHostsEvent) {
      yield await _mapDelHosts(event, state);
    }
  }

  /// 切换选中的hosts
  Future<HomeState> _mapChangeSelectedHosts(
      ChangeSelectedHostsEvent event, HomeState state) async {
    List<HostsInfoModel> oldHostsList = [];
    // 新的开关启用列表
    List<HostsInfoModel> hostsList = [];
    for (var item in state.hostsList) {
      // 保存原数据，用于还原
      oldHostsList.add(HostsInfoModel.fromJson(item.toJson()));

      // 处理切换打开信息
      if (item.key == event.selectedHosts) {
        item.check = event.isCheck;
      } else if (item.isBaseHosts) {
        // 基础配置保证为选中
        item.check = true;
      } else if (event.hostsMutex) {
        // 不是基础配置且开启互斥，则设置为false
        item.check = false;
      }
      hostsList.add(item);
    }

    // 更新本地hosts配置列表
    File hostsFile = await getHostsJsonFile();
    await hostsFile.writeAsString(json.encode(hostsList),
        flush: true); // 写入默认列表

    // 保存hosts到系统hosts
    bool isSaveOk = await changeSystemHosts(event.context);
    log('保存hosts失败了 $isSaveOk');
    // 保存失败，不切换
    if (!isSaveOk) {
      // 还原本地hosts配置列表
      File hostsFile = await getHostsJsonFile();
      await hostsFile.writeAsString(json.encode(oldHostsList),
          flush: true); // 写入默认列表
      return state.copyWith(
        hostsList: oldHostsList,
        changeHostList: state.changeHostList + 1,
      );
    }

    log('需要更新hosts');
    return state.copyWith(
      hostsList: hostsList,
      changeHostList: state.changeHostList + 1,
    );
  }

  /// 初始化hosts配置列表
  Future<HomeState> _mapInitHostsList(
      InitHostsListEvent event, HomeState state) async {
    if (event.lang == null || event.lang.get("public.app_name") == '') {
      return state;
    }
    List<HostsInfoModel> hostsList = [];
    try {
      String rootPath = await getAppRootDirectory();
      if (rootPath != null) {
        log('存储路径 $rootPath');
        // 列表缓存目录
        File hostsFile = await getHostsJsonFile();
        // 不存在则创建
        if (!hostsFile.existsSync()) {
          hostsList = await _firstStartApp(event.lang);
        } else {
          String jsonStr = hostsFile.readAsStringSync();
          log('读取历史hosts列表 ${jsonStr}');
          var obj = json.decode(jsonStr);
          if (obj != null) {
            hostsList =
                (obj as List).map((i) => HostsInfoModel.fromJson(i)).toList();
          }
        }
      }
    } catch (e) {
      log('初始化hosts配置列表错误1 ${e.toString()}');
      EasyLoading.showError(e.toString());
    }

    String showHosts = '';
    for (var item in hostsList) {
      if (item.isBaseHosts == true) {
        showHosts = item.key;
        break;
      }
    }

    log('默认选中 ${showHosts}');

    return state.copyWith(
      showHosts: showHosts,
      hostsList: hostsList,
      changeHostList: state.changeHostList + 1,
    );
  }

  /// 切换右侧展示hosts
  HomeState _mapChangeShowHosts(ChangeShowHostsEvent event, HomeState state) {
    return state.copyWith(
      showHosts: event.showHosts,
      changeHostList: state.changeHostList + 1,
    );
  }

  /// 切换列表编辑状态
  HomeState _mapChangeEditList(ChangeEditListEvent event, HomeState state) {
    return state.copyWith(
      editList: event.editList,
      changeHostList: state.changeHostList + 1,
    );
  }

  /// 添加hosts配置
  Future<HomeState> _mapAddHosts(AddHostsEvent event, HomeState state) async {
    List<HostsInfoModel> hostsList = state.hostsList;
    // 写入基本数据
    String key = _generateSha1(event.name);
    File hostsPath = await getHostsConfFile(key);
    if (hostsPath.existsSync()) {
      EasyLoading.showError('文件已存在！！！');
      return state;
    }
    // 创建hosts配置内容文件
    hostsPath.writeAsStringSync('# ${event.name}\n');

    hostsList.add(HostsInfoModel(
      key: key,
      name: event.name,
      check: false,
      isBaseHosts: false,
    ));

    // 更新hosts配置列表
    File hostsFile = await getHostsJsonFile();
    hostsFile.writeAsStringSync(json.encode(hostsList)); // 写入默认列表

    return state.copyWith(
      showHosts: key,
      hostsList: hostsList,
      changeHostList: state.changeHostList + 1,
    );
  }

  /// 删除一个hosts配置
  Future<HomeState> _mapDelHosts(DelHostsEvent event, HomeState state) async {
    // 是否删除当前查看hosts配置
    String showHosts = state.showHosts;
    if (event.key == state.showHosts) {
      showHosts = '';
    }

    // 删除文件
    File hostsPath = await getHostsConfFile(event.key);
    hostsPath.deleteSync();
    // 从列表删除
    List<HostsInfoModel> hostsList = [];
    for (var item in state.hostsList) {
      if (item.key != event.key) {
        hostsList.add(item);
      }
    }

    // 更新hosts配置列表
    File hostsFile = await getHostsJsonFile();
    hostsFile.writeAsStringSync(json.encode(hostsList)); // 写入默认列表

    return state.copyWith(
      showHosts: showHosts,
      hostsList: hostsList,
      changeHostList: state.changeHostList + 1,
    );
  }

  // 初始化hosts文件处理
  Future<List<HostsInfoModel>> _firstStartApp(I18N lang) async {
    List<HostsInfoModel> hostsList = [];
    try {
      File hostsFile = await getHostsJsonFile();
      // 不存在则创建
      if (!hostsFile.existsSync()) {
        await hostsFile.create();
        // 不存在时，备份系统hosts文件，并创建一条系统hosts记录
        log('不存在列表记录，备份系统hosts，并创建一条');
        String backupName = lang.get('home.backup_hosts');
        String sysHostsPath = '/etc/hosts';
        if (Platform.isWindows) {
          sysHostsPath = 'C:\\Windows\\System32\\drivers\\etc\\hosts';
        }
        File systemFile = File(sysHostsPath);
        String backupFilePath =
            await getHostsConfFilePath(_generateSha1(backupName));
        File backupFile = await systemFile.copy(backupFilePath);
        log('backupFile 路径 ${backupFile.path} 系统hosts备份后内容 ${backupFile.readAsStringSync()}');

        // 基础hosts配置
        String baseName = lang.get('home.base_hosts');

        File baseFile = await getHostsConfFile(_generateSha1(baseName));

        baseFile.writeAsStringSync('''##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1 localhost
255.255.255.255 broadcasthost
::1             localhost

''');
        // 存储列表
        hostsList.add(HostsInfoModel(
          key: _generateSha1(baseName),
          name: baseName,
          check: true,
          isBaseHosts: true,
        ));
        // 追加一个系统hosts配置
        hostsList.add(HostsInfoModel(
          key: _generateSha1(backupName),
          name: backupName,
          check: true,
        ));
        await hostsFile.writeAsString(json.encode(hostsList)); // 写入默认列表
      }
    } catch (e) {
      log('初始化hosts配置列表错误2 ${e.toString()}');
      EasyLoading.showError(
          'The first startup encountered an error. Please back up your hosts file\nerror：' +
              e.toString());
    }
    return hostsList;
  }

  /// 计算字符串md5
  String _generateSha1(String name) {
    var bytes = utf8.encode(name);
    Digest digest = sha1.convert(bytes);
    return digest.toString();
  }
}
