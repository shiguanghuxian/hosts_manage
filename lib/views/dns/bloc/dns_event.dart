part of 'dns_bloc.dart';

abstract class DNSEvent extends Equatable {
  const DNSEvent();
}

// 设置本机dns代理地址
class ChangeLocalDnsAddrEvent extends DNSEvent {
  final String localDnsAddr;

  const ChangeLocalDnsAddrEvent(this.localDnsAddr);

  @override
  List<Object> get props => [localDnsAddr];

  @override
  String toString() => 'ChangeLocalDnsAddrEvent { $localDnsAddr }';
}

// 保存公网dns服务配置列表
class ChangeDnsServersEvent extends DNSEvent {
  final String dnsServers;

  const ChangeDnsServersEvent(this.dnsServers);

  @override
  List<Object> get props => [dnsServers];

  @override
  String toString() => 'ChangeDnsServersEvent { $dnsServers }';
}
