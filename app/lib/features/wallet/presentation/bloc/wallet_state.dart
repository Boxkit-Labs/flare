import 'package:equatable/equatable.dart';
import 'package:flare_app/core/models/models.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final WalletModel? wallet;
  final SpendingStatsModel? stats;
  final List<TransactionModel> transactions;
  final bool isFunding;
  const WalletLoaded({
    this.wallet,
    this.stats,
    this.transactions = const [],
    this.isFunding = false,
  });

  @override
  List<Object?> get props => [wallet, stats, transactions, isFunding];
}

class WalletError extends WalletState {
  final String message;
  const WalletError(this.message);

  @override
  List<Object?> get props => [message];
}
