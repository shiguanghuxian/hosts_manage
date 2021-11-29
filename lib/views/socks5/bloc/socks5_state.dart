part of 'socks5_bloc.dart';

class Socks5State extends Equatable {
  const Socks5State({
    this.localSocks5Addr = '127.0.0.1:10109',
    this.socks5Hosts = '',
  });

  final String localSocks5Addr;
  final String socks5Hosts;

  Socks5State copyWith({
    String localSocks5Addr,
    String socks5Hosts,
  }) {
    return Socks5State(
      localSocks5Addr: localSocks5Addr ?? this.localSocks5Addr,
      socks5Hosts: socks5Hosts ?? this.socks5Hosts,
    );
  }

  @override
  List<Object> get props => [localSocks5Addr, socks5Hosts];
}
