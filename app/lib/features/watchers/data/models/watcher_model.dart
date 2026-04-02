enum WatcherType {
  flight,
  crypto,
  news,
  product,
  job,
  custom;

  static WatcherType fromString(String value) {
    return WatcherType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WatcherType.custom,
    );
  }

  @override
  String toString() => name;
}

enum WatcherStatus {
  active,
  pausedBudget,
  pausedManual,
  pausedWallet,
  error;

  static WatcherStatus fromString(String value) {
    return WatcherStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WatcherStatus.active,
    );
  }

  @override
  String toString() => name;
}

class WatcherModel {
  final String watcherId;
  final String userId;
  final String name;
  final WatcherType type;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> alertConditions;
  final int checkIntervalMinutes;
  final double weeklyBudgetUsdc;
  final double spentThisWeekUsdc;
  final String priority;
  final WatcherStatus status;
  final String? errorMessage;
  final DateTime? lastCheckAt;
  final DateTime? nextCheckAt;
  final int totalChecks;
  final int totalFindings;
  final double totalSpentUsdc;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WatcherModel({
    required this.watcherId,
    required this.userId,
    required this.name,
    required this.type,
    required this.parameters,
    required this.alertConditions,
    this.checkIntervalMinutes = 60,
    required this.weeklyBudgetUsdc,
    this.spentThisWeekUsdc = 0.0,
    this.priority = "medium",
    this.status = WatcherStatus.active,
    this.errorMessage,
    this.lastCheckAt,
    this.nextCheckAt,
    this.totalChecks = 0,
    this.totalFindings = 0,
    this.totalSpentUsdc = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WatcherModel.fromJson(Map<String, dynamic> json) {
    return WatcherModel(
      watcherId: json['watcherId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      type: WatcherType.fromString(json['type'] as String),
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
      alertConditions: json['alertConditions'] as Map<String, dynamic>? ?? {},
      checkIntervalMinutes: json['checkIntervalMinutes'] as int? ?? 60,
      weeklyBudgetUsdc: (json['weeklyBudgetUsdc'] as num).toDouble(),
      spentThisWeekUsdc: (json['spentThisWeekUsdc'] as num? ?? 0.0).toDouble(),
      priority: json['priority'] as String? ?? "medium",
      status: WatcherStatus.fromString(json['status'] as String),
      errorMessage: json['errorMessage'] as String?,
      lastCheckAt: json['lastCheckAt'] != null
          ? DateTime.parse(json['lastCheckAt'] as String)
          : null,
      nextCheckAt: json['nextCheckAt'] != null
          ? DateTime.parse(json['nextCheckAt'] as String)
          : null,
      totalChecks: json['totalChecks'] as int? ?? 0,
      totalFindings: json['totalFindings'] as int? ?? 0,
      totalSpentUsdc: (json['totalSpentUsdc'] as num? ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'watcherId': watcherId,
      'userId': userId,
      'name': name,
      'type': type.name,
      'parameters': parameters,
      'alertConditions': alertConditions,
      'checkIntervalMinutes': checkIntervalMinutes,
      'weeklyBudgetUsdc': weeklyBudgetUsdc,
      'spentThisWeekUsdc': spentThisWeekUsdc,
      'priority': priority,
      'status': status.name,
      'errorMessage': errorMessage,
      'lastCheckAt': lastCheckAt?.toIso8601String(),
      'nextCheckAt': nextCheckAt?.toIso8601String(),
      'totalChecks': totalChecks,
      'totalFindings': totalFindings,
      'totalSpentUsdc': totalSpentUsdc,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  WatcherModel copyWith({
    String? watcherId,
    String? userId,
    String? name,
    WatcherType? type,
    Map<String, dynamic>? parameters,
    Map<String, dynamic>? alertConditions,
    int? checkIntervalMinutes,
    double? weeklyBudgetUsdc,
    double? spentThisWeekUsdc,
    String? priority,
    WatcherStatus? status,
    String? errorMessage,
    DateTime? lastCheckAt,
    DateTime? nextCheckAt,
    int? totalChecks,
    int? totalFindings,
    double? totalSpentUsdc,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WatcherModel(
      watcherId: watcherId ?? this.watcherId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
      alertConditions: alertConditions ?? this.alertConditions,
      checkIntervalMinutes: checkIntervalMinutes ?? this.checkIntervalMinutes,
      weeklyBudgetUsdc: weeklyBudgetUsdc ?? this.weeklyBudgetUsdc,
      spentThisWeekUsdc: spentThisWeekUsdc ?? this.spentThisWeekUsdc,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      lastCheckAt: lastCheckAt ?? this.lastCheckAt,
      nextCheckAt: nextCheckAt ?? this.nextCheckAt,
      totalChecks: totalChecks ?? this.totalChecks,
      totalFindings: totalFindings ?? this.totalFindings,
      totalSpentUsdc: totalSpentUsdc ?? this.totalSpentUsdc,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
