class CheckResultModel {
  final String checkId;
  final String watcherId;
  final String serviceName;
  final Map<String, dynamic> responseData;
  final double costUsdc;
  final String stellarTxHash;
  final bool findingDetected;
  final String? findingId;
  final String agentReasoning;
  final DateTime checkedAt;

  const CheckResultModel({
    required this.checkId,
    required this.watcherId,
    required this.serviceName,
    required this.responseData,
    required this.costUsdc,
    required this.stellarTxHash,
    required this.findingDetected,
    this.findingId,
    required this.agentReasoning,
    required this.checkedAt,
  });

  factory CheckResultModel.fromJson(Map<String, dynamic> json) {
    return CheckResultModel(
      checkId: json['checkId'] as String,
      watcherId: json['watcherId'] as String,
      serviceName: json['serviceName'] as String,
      responseData: json['responseData'] as Map<String, dynamic>? ?? {},
      costUsdc: (json['costUsdc'] as num).toDouble(),
      stellarTxHash: json['stellarTxHash'] as String? ?? "",
      findingDetected: json['findingDetected'] as bool? ?? false,
      findingId: json['findingId'] as String?,
      agentReasoning: json['agentReasoning'] as String? ?? "",
      checkedAt: json['checkedAt'] != null
          ? DateTime.parse(json['checkedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkId': checkId,
      'watcherId': watcherId,
      'serviceName': serviceName,
      'responseData': responseData,
      'costUsdc': costUsdc,
      'stellarTxHash': stellarTxHash,
      'findingDetected': findingDetected,
      'findingId': findingId,
      'agentReasoning': agentReasoning,
      'checkedAt': checkedAt.toIso8601String(),
    };
  }

  CheckResultModel copyWith({
    String? checkId,
    String? watcherId,
    String? serviceName,
    Map<String, dynamic>? responseData,
    double? costUsdc,
    String? stellarTxHash,
    bool? findingDetected,
    String? findingId,
    String? agentReasoning,
    DateTime? checkedAt,
  }) {
    return CheckResultModel(
      checkId: checkId ?? this.checkId,
      watcherId: watcherId ?? this.watcherId,
      serviceName: serviceName ?? this.serviceName,
      responseData: responseData ?? this.responseData,
      costUsdc: costUsdc ?? this.costUsdc,
      stellarTxHash: stellarTxHash ?? this.stellarTxHash,
      findingDetected: findingDetected ?? this.findingDetected,
      findingId: findingId ?? this.findingId,
      agentReasoning: agentReasoning ?? this.agentReasoning,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }
}
