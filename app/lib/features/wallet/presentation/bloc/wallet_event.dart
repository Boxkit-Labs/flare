import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class LoadWallet extends WalletEvent {
  final String userId;
  const LoadWallet(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadWalletStats extends WalletEvent {
  final String userId;
  const LoadWalletStats(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadTransactions extends WalletEvent {
  final String userId;
  final int limit;
  final int offset;
  const LoadTransactions(this.userId, {this.limit = 20, this.offset = 0});

  @override
  List<Object?> get props => [userId, limit, offset];
}
