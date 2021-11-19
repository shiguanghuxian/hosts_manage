part of 'dns_bloc.dart';

class DNSState extends Equatable {
  const DNSState({
    this.localDnsAddr = '127.0.0.1:53',
    this.dnsServers = '',
  });

  final String localDnsAddr;
  final String dnsServers;

  DNSState copyWith({
    String localDnsAddr,
    String dnsServers,
  }) {
    return DNSState(
      localDnsAddr: localDnsAddr ?? this.localDnsAddr,
      dnsServers: dnsServers ?? this.dnsServers,
    );
  }

  @override
  List<Object> get props => [localDnsAddr, dnsServers];
}
