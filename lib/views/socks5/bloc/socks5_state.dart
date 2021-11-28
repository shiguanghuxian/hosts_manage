part of 'socks5_bloc.dart';

class Socks5State extends Equatable {
  const Socks5State({
    this.localSocks5Addr = '127.0.0.1:10109',
  });

  final String localSocks5Addr;

  Socks5State copyWith({
    String localSocks5Addr,
  }) {
    return Socks5State(
      localSocks5Addr: localSocks5Addr ?? this.localSocks5Addr,
    );
  }

  @override
  List<Object> get props => [localSocks5Addr];
}
