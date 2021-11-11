part of 'dns_bloc.dart';

abstract class DNSEvent extends Equatable {
  const DNSEvent();
}

// 
class ChangeChannelEvent extends DNSEvent {
  final int index;

  const ChangeChannelEvent(this.index);

  @override
  List<Object> get props => [index];

  @override
  String toString() => 'ChangeChannelEvent { tab: $index }';
}
