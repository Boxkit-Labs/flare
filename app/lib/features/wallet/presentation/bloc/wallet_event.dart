import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllWalletData extends WalletEvent {
  final String userId;
  final bool isRefresh;
  const LoadAllWalletData(this.userId, {this.isRefresh = false});

  @override
  List<Object?> get props => [userId, isRefresh];
}

class FundWalletUser extends WalletEvent {
  final String userId;
  const FundWalletUser(this.userId);

  @override
  List<Object?> get props => [userId];
}
