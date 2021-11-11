part of 'dns_bloc.dart';

class DNSState extends Equatable {
  const DNSState({
    this.index = 0,
  });

  final int index;

  DNSState copyWith({
    int index,
  }) {
    return DNSState(
      index: index ?? this.index,
    );
  }

  @override
  List<Object> get props =>
      [index];
}
