part of 'socks5_bloc.dart';

abstract class Socks5Event extends Equatable {
  const Socks5Event();
}

// 设置本机socks5代理地址
class ChangeLocalSocks5AddrEvent extends Socks5Event {
  final String localSocks5Addr;

  const ChangeLocalSocks5AddrEvent(this.localSocks5Addr);

  @override
  List<Object> get props => [localSocks5Addr];

  @override
  String toString() => 'ChangeLocalSocks5AddrEvent { $localSocks5Addr }';
}

/// 设置需要代理加速域名
class ChangeSocks5HostsEvent extends Socks5Event {
  final String socks5Hosts;

  const ChangeSocks5HostsEvent(this.socks5Hosts);

  @override
  List<Object> get props => [socks5Hosts];

  @override
  String toString() => 'ChangeSocks5HostsEvent { $socks5Hosts }';
}
