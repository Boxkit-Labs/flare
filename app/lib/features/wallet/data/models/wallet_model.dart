import 'transaction_model.dart';

class WalletModel {
  final String publicKey;
  final double balanceUsdc;
  final double spentToday;
  final double spentThisWeek;
  final List<TransactionModel> transactions;

  const WalletModel({
    required this.publicKey,
    required this.balanceUsdc,
    this.spentToday = 0.0,
    this.spentThisWeek = 0.0,
    required this.transactions,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      publicKey: json['publicKey'] as String,
      balanceUsdc: (json['balanceUsdc'] as num? ?? 0.0).toDouble(),
      spentToday: (json['spentToday'] as num? ?? 0.0).toDouble(),
      spentThisWeek: (json['spentThisWeek'] as num? ?? 0.0).toDouble(),
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'publicKey': publicKey,
      'balanceUsdc': balanceUsdc,
      'spentToday': spentToday,
      'spentThisWeek': spentThisWeek,
      'transactions': transactions.map((e) => e.toJson()).toList(),
    };
  }

  WalletModel copyWith({
    String? publicKey,
    double? balanceUsdc,
    double? spentToday,
    double? spentThisWeek,
    List<TransactionModel>? transactions,
  }) {
    return WalletModel(
      publicKey: publicKey ?? this.publicKey,
      balanceUsdc: balanceUsdc ?? this.balanceUsdc,
      spentToday: spentToday ?? this.spentToday,
      spentThisWeek: spentThisWeek ?? this.spentThisWeek,
      transactions: transactions ?? this.transactions,
    );
  }
}
