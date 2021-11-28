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

/// 设置公网dns服务器列表
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

/* 以下socks5代理 */

/// 启动socks5服务
typedef Socks5Start = void Function();
final Socks5Start socks5Start =
    _lib.lookup<NativeFunction<Void Function()>>('Socks5Start').asFunction();

/// 停止socks5服务
typedef Socks5Stop = void Function();
final Socks5Stop socks5Stop =
    _lib.lookup<NativeFunction<Void Function()>>('Socks5Stop').asFunction();

/// 获取当前socks5服务是否启动 1启动 0未启动
typedef Socks5GetIsStart = int Function();
final Socks5GetIsStart socks5GetIsStart = _lib
    .lookup<NativeFunction<Int32 Function()>>('Socks5GetIsStart')
    .asFunction();

/// 获取socks5启动或停止错误
typedef Socks5GetErr = Pointer<Int8> Function();
final Socks5GetErr socks5GetErr = _lib
    .lookup<NativeFunction<Pointer<Int8> Function()>>('Socks5GetErr')
    .asFunction();

/// 设置证书根路径
typedef Socks5SetCertPath = void Function(Pointer<GoString>);
final Socks5SetCertPath socks5SetCertPath = _lib
    .lookup<NativeFunction<Void Function(Pointer<GoString>)>>(
        'Socks5SetCertPath')
    .asFunction();

/// 获取socks5启动或停止错误
typedef Socks5GenCaCert = Pointer<Int8> Function();
final Socks5GenCaCert socks5GenCaCert = _lib
    .lookup<NativeFunction<Pointer<Int8> Function()>>('Socks5GenCaCert')
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
