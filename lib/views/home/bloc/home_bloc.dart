import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hosts_manage/i18n/i18n.dart';
import 'package:hosts_manage/models/hosts_info_model.dart';
import 'package:path_provider/path_provider.dart';

part "home_event.dart";
part "home_state.dart";

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState());

  @override
  Stream<HomeState> mapEventToState(HomeEvent event) async* {
    if (event is ChangeSelectedHostsEvent) {
      yield _mapChangeSelectedHosts(event, state);
    } else if (event is InitHostsListEvent) {
      yield await _mapInitHostsList(event, state);
    } else if (event is ChangeShowHostsEvent) {
      yield _mapChangeShowHosts(event, state);
    } else if (event is ChangeEditListEvent) {
      yield _mapChangeEditList(event, state);
    }
  }

  /// 切换选中的hosts
  HomeState _mapChangeSelectedHosts(
      ChangeSelectedHostsEvent event, HomeState state) {
    List<HostsInfoModel> hostsList = [];
    for (var item in state.hostsList) {
      if (item.key == event.selectedHosts) {
        item.check = event.isCheck;
      }
      hostsList.add(item);
    }
    // TODO 更新hosts 或刷新dns服务
    log('需要更新hosts');
    return state.copyWith(
      hostsList: hostsList,
      showHosts: event.selectedHosts,
      changeHostList: state.changeHostList + 1,
    );
  }

  /// 初始化hosts配置列表
  Future<HomeState> _mapInitHostsList(
      InitHostsListEvent event, HomeState state) async {
    List<HostsInfoModel> hostsList = [];
    try {
      Directory libDir = await getLibraryDirectory();
      if (libDir != null) {
        log('存储路径 ${libDir.path}');
        // 列表缓存目录
        File hostsFile = File(libDir.path + "/" + "hosts.json");
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
      log('初始化hosts配置列表错误 ${e.toString()}');
      EasyLoading.showError(e.toString());
    }

    String showHosts = '';
    for (var item in hostsList) {
      if (item.isBaseHosts) {
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

  // 初始化hosts文件处理
  Future<List<HostsInfoModel>> _firstStartApp(I18N lang) async {
    List<HostsInfoModel> hostsList = [];
    try {
      Directory libDir = await getLibraryDirectory();
      File hostsFile = File(libDir.path + "/" + "hosts.json");
      // 不存在则创建
      if (!hostsFile.existsSync()) {
        await hostsFile.create();
        // 不存在时，备份系统hosts文件，并创建一条系统hosts记录
        log('不存在列表记录，备份系统hosts，并创建一条');
        String backupName = lang.get('home.backup_hosts');
        File systemFile = File('/etc/hosts');
        File backupFile = await systemFile
            .copy(libDir.path + "/" + _generateSha1(backupName) + ".json");
        log('backupFile 路径 ${backupFile.path} 系统hosts备份后内容 ${backupFile.readAsStringSync()}');

        // 基础hosts配置
        String baseName = lang.get('home.base_hosts');

        File baseFile =
            File(libDir.path + "/" + _generateSha1(baseName) + ".json");
        baseFile.writeAsString('''##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1	localhost
255.255.255.255	broadcasthost
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
        hostsFile.writeAsString(json.encode(hostsList)); // 写入默认列表
      }
    } catch (e) {
      log('初始化hosts配置列表错误 ${e.toString()}');
      EasyLoading.showError('首次启动遇到错误，请备份你的hosts文件\n错误：' + e.toString());
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
