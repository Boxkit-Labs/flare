class TransactionModel {
  final String txId;
  final String userId;
  final String watcherId;
  final double amountUsdc;
  final String serviceName;
  final String stellarTxHash;
  final String stellarExplorerUrl;
  final DateTime timestamp;

  const TransactionModel({
    required this.txId,
    required this.userId,
    required this.watcherId,
    required this.amountUsdc,
    required this.serviceName,
    required this.stellarTxHash,
    required this.stellarExplorerUrl,
    required this.timestamp,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      txId: json['txId'] as String,
      userId: json['userId'] as String,
      watcherId: json['watcherId'] as String,
      amountUsdc: (json['amountUsdc'] as num? ?? 0.0).toDouble(),
      serviceName: json['serviceName'] as String? ?? "Unknown",
      stellarTxHash: json['stellarTxHash'] as String? ?? "",
      stellarExplorerUrl: json['stellarExplorerUrl'] as String? ?? "",
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'txId': txId,
      'userId': userId,
      'watcherId': watcherId,
      'amountUsdc': amountUsdc,
      'serviceName': serviceName,
      'stellarTxHash': stellarTxHash,
      'stellarExplorerUrl': stellarExplorerUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? txId,
    String? userId,
    String? watcherId,
    double? amountUsdc,
    String? serviceName,
    String? stellarTxHash,
    String? stellarExplorerUrl,
    DateTime? timestamp,
  }) {
    return TransactionModel(
      txId: txId ?? this.txId,
      userId: userId ?? this.userId,
      watcherId: watcherId ?? this.watcherId,
      amountUsdc: amountUsdc ?? this.amountUsdc,
      serviceName: serviceName ?? this.serviceName,
      stellarTxHash: stellarTxHash ?? this.stellarTxHash,
      stellarExplorerUrl: stellarExplorerUrl ?? this.stellarExplorerUrl,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
