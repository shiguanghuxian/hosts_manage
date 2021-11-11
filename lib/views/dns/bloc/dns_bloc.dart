import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'dns_event.dart';
part 'dns_state.dart';

class DNSBloc extends Bloc<DNSEvent, DNSState> {
  DNSBloc() : super(const DNSState());

  @override
  Stream<DNSState> mapEventToState(DNSEvent event) async* {
    if (event is ChangeChannelEvent) {
      yield _mapChangeChannel(event, state);
    }
  }

  //
  DNSState _mapChangeChannel(ChangeChannelEvent event, DNSState state) {
    return state.copyWith(
      index: event.index,
    );
  }
}
