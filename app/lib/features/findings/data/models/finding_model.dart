class FindingModel {
  final String findingId;
  final String watcherId;
  final String checkId;
  final String userId;
  final String type;
  final String headline;
  final String detail;
  final Map<String, dynamic> data;
  final String? actionUrl;
  final double costUsdc;
  final String stellarTxHash;
  final bool read;
  final DateTime foundAt;

  const FindingModel({
    required this.findingId,
    required this.watcherId,
    required this.checkId,
    required this.userId,
    required this.type,
    required this.headline,
    required this.detail,
    required this.data,
    this.actionUrl,
    required this.costUsdc,
    required this.stellarTxHash,
    this.read = false,
    required this.foundAt,
  });

  factory FindingModel.fromJson(Map<String, dynamic> json) {
    return FindingModel(
      findingId: json['findingId'] as String,
      watcherId: json['watcherId'] as String,
      checkId: json['checkId'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String? ?? "general",
      headline: json['headline'] as String? ?? "",
      detail: json['detail'] as String? ?? "",
      data: json['data'] as Map<String, dynamic>? ?? {},
      actionUrl: json['actionUrl'] as String?,
      costUsdc: (json['costUsdc'] as num? ?? 0.0).toDouble(),
      stellarTxHash: json['stellarTxHash'] as String? ?? "",
      read: json['read'] as bool? ?? false,
      foundAt: json['foundAt'] != null
          ? DateTime.parse(json['foundAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'findingId': findingId,
      'watcherId': watcherId,
      'checkId': checkId,
      'userId': userId,
      'type': type,
      'headline': headline,
      'detail': detail,
      'data': data,
      'actionUrl': actionUrl,
      'costUsdc': costUsdc,
      'stellarTxHash': stellarTxHash,
      'read': read,
      'foundAt': foundAt.toIso8601String(),
    };
  }

  FindingModel copyWith({
    String? findingId,
    String? watcherId,
    String? checkId,
    String? userId,
    String? type,
    String? headline,
    String? detail,
    Map<String, dynamic>? data,
    String? actionUrl,
    double? costUsdc,
    String? stellarTxHash,
    bool? read,
    DateTime? foundAt,
  }) {
    return FindingModel(
      findingId: findingId ?? this.findingId,
      watcherId: watcherId ?? this.watcherId,
      checkId: checkId ?? this.checkId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      headline: headline ?? this.headline,
      detail: detail ?? this.detail,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      costUsdc: costUsdc ?? this.costUsdc,
      stellarTxHash: stellarTxHash ?? this.stellarTxHash,
      read: read ?? this.read,
      foundAt: foundAt ?? this.foundAt,
    );
  }
}
