import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'socks5_event.dart';
part 'socks5_state.dart';

class Socks5Bloc extends Bloc<Socks5Event, Socks5State> {
  Socks5Bloc() : super(const Socks5State());

  @override
  Stream<Socks5State> mapEventToState(Socks5Event event) async* {
    if (event is ChangeLocalSocks5AddrEvent) {
      yield _mapChangeLocalSocks5Addr(event, state);
    } else if (event is ChangeSocks5HostsEvent) {
      yield _mapChangeSocks5Hosts(event, state);
    }
  }

  // 设置本机socks5代理地址
  Socks5State _mapChangeLocalSocks5Addr(
      ChangeLocalSocks5AddrEvent event, Socks5State state) {
    return state.copyWith(
      localSocks5Addr: event.localSocks5Addr,
    );
  }

  /// 设置需要代理加速域名
  Socks5State _mapChangeSocks5Hosts(
      ChangeSocks5HostsEvent event, Socks5State state) {
    return state.copyWith(
      socks5Hosts: event.socks5Hosts,
    );
  }
}
