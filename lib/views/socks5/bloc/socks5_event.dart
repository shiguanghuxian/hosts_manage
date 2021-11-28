part of 'socks5_bloc.dart';

abstract class Socks5Event extends Equatable {
  const Socks5Event();
}

// 设置本机dns代理地址
class ChangeLocalSocks5AddrEvent extends Socks5Event {
  final String localSocks5Addr;

  const ChangeLocalSocks5AddrEvent(this.localSocks5Addr);

  @override
  List<Object> get props => [localSocks5Addr];

  @override
  String toString() => 'ChangeLocalSocks5AddrEvent { $localSocks5Addr }';
}
