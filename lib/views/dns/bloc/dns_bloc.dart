import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'dns_event.dart';
part 'dns_state.dart';

class DNSBloc extends Bloc<DNSEvent, DNSState> {
  DNSBloc() : super(const DNSState());

  @override
  Stream<DNSState> mapEventToState(DNSEvent event) async* {
    if (event is ChangeLocalDnsAddrEvent) {
      yield _mapChangeLocalDnsAddr(event, state);
    } else if (event is ChangeDnsServersEvent) {
      yield _mapChangeDnsServers(event, state);
    }
  }

  // 设置本机dns代理地址
  DNSState _mapChangeLocalDnsAddr(
      ChangeLocalDnsAddrEvent event, DNSState state) {
    return state.copyWith(
      localDnsAddr: event.localDnsAddr,
    );
  }

  // 保存公网dns服务配置列表
  DNSState _mapChangeDnsServers(ChangeDnsServersEvent event, DNSState state) {
    return state.copyWith(
      dnsServers: event.dnsServers,
    );
  }
}
