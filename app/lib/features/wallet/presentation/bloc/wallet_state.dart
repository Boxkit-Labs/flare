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
  const WalletLoaded({this.wallet, this.stats, this.transactions = const []});

  @override
  List<Object?> get props => [wallet, stats, transactions];
}

class WalletError extends WalletState {
  final String message;
  const WalletError(this.message);

  @override
  List<Object?> get props => [message];
}
