import 'dart:ffi';
import 'dart:io';
import 'package:call/call.dart';
import 'package:ffi/ffi.dart';
import 'package:hosts_manage/golib/godart.dart';

/* 接入C函数，用于dart语言调用 */

// 加载动态库
DynamicLibrary _lib = Platform.isWindows
    ? getDyLibModule(getLibPath())
    : DynamicLibrary.open(getLibPath());

/// 启动服务
typedef Start = void Function();
final Start startDNS =
    _lib.lookup<NativeFunction<Void Function()>>('Start').asFunction();

/// 停止服务
typedef Stop = void Function();
final Stop stopDNS =
    _lib.lookup<NativeFunction<Void Function()>>('Stop').asFunction();

/// 设置ip映射
typedef SetAddressBook = void Function(Pointer<GoString>);
final SetAddressBook setAddressBookDNS = _lib
    .lookup<NativeFunction<Void Function(Pointer<GoString>)>>('SetAddressBook')
    .asFunction();

/// 设置ip映射
typedef SetPublicDnsServer = void Function(Pointer<GoString>);
final SetPublicDnsServer setPublicDnsServerDNS = _lib
    .lookup<NativeFunction<Void Function(Pointer<GoString>)>>(
        'SetPublicDnsServer')
    .asFunction();

/// 获取当前dns服务是否启动 1启动 0未启动
typedef GetIsStart = int Function();
final GetIsStart getIsStart =
    _lib.lookup<NativeFunction<Int32 Function()>>('GetIsStart').asFunction();

/// 获取启动或停止错误
typedef GetErr = Pointer<Int8> Function();
final GetErr getErr = _lib
    .lookup<NativeFunction<Pointer<Int8> Function()>>('GetErr')
    .asFunction();

// 根据系统平台加载不同的库文件
String getLibPath() {
  if (Platform.isMacOS) {
    return 'libdns.dylib';
  } else if (Platform.isWindows) {
    return 'lib/golib/libdns.dll';
  }
  return 'libdns.so';
}
