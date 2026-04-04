// Data models for the Flare app, mirroring backend database schemas.

class UserModel {
  final String userId;
  final String deviceId;
  final String stellarPublicKey;
  final String? fcmToken;
  final String briefingTime;
  final String timezone;
  final String dndStart;
  final String dndEnd;
  final double? globalDailyCap;
  final String createdAt;

  const UserModel({
    required this.userId,
    required this.deviceId,
    required this.stellarPublicKey,
    this.fcmToken,
    this.briefingTime = '07:00',
    this.timezone = 'UTC',
    this.dndStart = '23:00',
    this.dndEnd = '07:00',
    this.globalDailyCap,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return UserModel(
      userId: json['user_id'] ?? '',
      deviceId: json['device_id'] ?? '',
      stellarPublicKey: json['stellar_public_key'] ?? '',
      fcmToken: json['fcm_token'],
      briefingTime: json['briefing_time'] ?? '07:00',
      timezone: json['timezone'] ?? 'UTC',
      dndStart: json['dnd_start'] ?? '23:00',
      dndEnd: json['dnd_end'] ?? '07:00',
      globalDailyCap: parseDouble(json['global_daily_cap']),
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'device_id': deviceId,
        'stellar_public_key': stellarPublicKey,
        'fcm_token': fcmToken,
        'briefing_time': briefingTime,
        'timezone': timezone,
        'dnd_start': dndStart,
        'dnd_end': dndEnd,
        'global_daily_cap': globalDailyCap,
        'created_at': createdAt,
      };
}

class WatcherModel {
  final String watcherId;
  final String userId;
  final String name;
  final String type;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> alertConditions;
  final int checkIntervalMinutes;
  final double weeklyBudgetUsdc;
  final double spentThisWeekUsdc;
  final String? weekStart;
  final String priority;
  final String status;
  final String? errorMessage;
  final String? lastCheckAt;
  final String? nextCheckAt;
  final int totalChecks;
  final int totalFindings;
  final double totalSpentUsdc;
  final String createdAt;
  final String updatedAt;
  final double? budgetPercentUsed;

  // Detail sub-models (populated when fetching single watcher)
  final List<CheckModel>? recentChecks;
  final List<FindingModel>? recentFindings;

  const WatcherModel({
    required this.watcherId,
    required this.userId,
    required this.name,
    required this.type,
    required this.parameters,
    required this.alertConditions,
    required this.checkIntervalMinutes,
    required this.weeklyBudgetUsdc,
    this.spentThisWeekUsdc = 0,
    this.weekStart,
    this.priority = 'medium',
    this.status = 'active',
    this.errorMessage,
    this.lastCheckAt,
    this.nextCheckAt,
    this.totalChecks = 0,
    this.totalFindings = 0,
    this.totalSpentUsdc = 0,
    required this.createdAt,
    required this.updatedAt,
    this.budgetPercentUsed,
    this.recentChecks,
    this.recentFindings,
  });

  factory WatcherModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return WatcherModel(
      watcherId: json['watcher_id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      parameters: json['parameters'] is Map
          ? Map<String, dynamic>.from(json['parameters'])
          : {},
      alertConditions: json['alert_conditions'] is Map
          ? Map<String, dynamic>.from(json['alert_conditions'])
          : {},
      checkIntervalMinutes: json['check_interval_minutes'] ?? 60,
      weeklyBudgetUsdc: parseDouble(json['weekly_budget_usdc'], 0),
      spentThisWeekUsdc: parseDouble(json['spent_this_week_usdc'], 0),
      weekStart: json['week_start'],
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'active',
      errorMessage: json['error_message'],
      lastCheckAt: json['last_check_at'],
      nextCheckAt: json['next_check_at'],
      totalChecks: json['total_checks'] ?? 0,
      totalFindings: json['total_findings'] ?? 0,
      totalSpentUsdc: parseDouble(json['total_spent_usdc'], 0),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      budgetPercentUsed: parseDouble(json['budget_percent_used'], 0),
      recentChecks: json['recent_checks'] != null
          ? (json['recent_checks'] as List)
              .map((c) => CheckModel.fromJson(c))
              .toList()
          : null,
      recentFindings: json['recent_findings'] != null
          ? (json['recent_findings'] as List)
              .map((f) => FindingModel.fromJson(f))
              .toList()
          : null,
    );
  }
}

class CheckModel {
  final String checkId;
  final String watcherId;
  final String userId;
  final String serviceName;
  final Map<String, dynamic>? requestPayload;
  final Map<String, dynamic>? responseData;
  final double costUsdc;
  final String? stellarTxHash;
  final bool findingDetected;
  final String? findingId;
  final String? agentReasoning;
  final String checkedAt;

  const CheckModel({
    required this.checkId,
    required this.watcherId,
    required this.userId,
    required this.serviceName,
    this.requestPayload,
    this.responseData,
    required this.costUsdc,
    this.stellarTxHash,
    this.findingDetected = false,
    this.findingId,
    this.agentReasoning,
    required this.checkedAt,
  });

  factory CheckModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return CheckModel(
      checkId: json['check_id'] ?? '',
      watcherId: json['watcher_id'] ?? '',
      userId: json['user_id'] ?? '',
      serviceName: json['service_name'] ?? '',
      requestPayload: json['request_payload'] is Map
          ? Map<String, dynamic>.from(json['request_payload'])
          : null,
      responseData: json['response_data'] is Map
          ? Map<String, dynamic>.from(json['response_data'])
          : null,
      costUsdc: parseDouble(json['cost_usdc'], 0),
      stellarTxHash: json['stellar_tx_hash'],
      findingDetected:
          json['finding_detected'] == 1 || json['finding_detected'] == true,
      findingId: json['finding_id'],
      agentReasoning: json['agent_reasoning'],
      checkedAt: json['checked_at'] ?? '',
    );
  }
}

class FindingModel {
  final String findingId;
  final String watcherId;
  final String checkId;
  final String userId;
  final String type;
  final String headline;
  final String? detail;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final double costUsdc;
  final String? stellarTxHash;
  final bool isRead;
  final bool isNotified;
  final String foundAt;
  final String? watcherName;
  final String? watcherType;

  const FindingModel({
    required this.findingId,
    required this.watcherId,
    required this.checkId,
    required this.userId,
    required this.type,
    required this.headline,
    this.detail,
    this.data,
    this.actionUrl,
    required this.costUsdc,
    this.stellarTxHash,
    this.isRead = false,
    this.isNotified = false,
    required this.foundAt,
    this.watcherName,
    this.watcherType,
  });

  factory FindingModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return FindingModel(
      findingId: json['finding_id'] ?? '',
      watcherId: json['watcher_id'] ?? '',
      checkId: json['check_id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      headline: json['headline'] ?? '',
      detail: json['detail'],
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      actionUrl: json['action_url'],
      costUsdc: parseDouble(json['cost_usdc'], 0),
      stellarTxHash: json['stellar_tx_hash'],
      isRead: json['read'] == 1 || json['read'] == true,
      isNotified: json['notified'] == 1 || json['notified'] == true,
      foundAt: json['found_at'] ?? '',
      watcherName: json['watcher_name'],
      watcherType: json['watcher_type'],
    );
  }
}

class WatcherSummary {
  final String watcherId;
  final String watcherName;
  final int checksRun;
  final int findingsCount;
  final double spent;
  final String latestDataSummary;
  final String type;

  const WatcherSummary({
    required this.watcherId,
    required this.watcherName,
    required this.checksRun,
    required this.findingsCount,
    required this.spent,
    required this.latestDataSummary,
    required this.type,
  });

  factory WatcherSummary.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return WatcherSummary(
      watcherId: json['watcher_id'] ?? json['watcherId'] ?? '',
      watcherName: json['watcher_name'] ?? json['watcherName'] ?? '',
      checksRun: json['checks_run'] ?? json['checksRun'] ?? 0,
      findingsCount: json['findings_count'] ?? json['findingsCount'] ?? 0,
      spent: parseDouble(json['spent'], 0),
      latestDataSummary: json['latest_data_summary'] ?? json['latestDataSummary'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class BriefingModel {
  final String briefingId;
  final String userId;
  final String date;
  final String periodStart;
  final String periodEnd;
  final int totalChecks;
  final int totalFindings;
  final double totalCostUsdc;
  final List<dynamic> findingsJson;
  final List<WatcherSummary> watcherSummaries;
  final String? generatedSummary;
  final bool isRead;
  final String generatedAt;

  const BriefingModel({
    required this.briefingId,
    required this.userId,
    required this.date,
    required this.periodStart,
    required this.periodEnd,
    this.totalChecks = 0,
    this.totalFindings = 0,
    this.totalCostUsdc = 0,
    this.findingsJson = const [],
    this.watcherSummaries = const [],
    this.generatedSummary,
    this.isRead = false,
    required this.generatedAt,
  });

  factory BriefingModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return BriefingModel(
      briefingId: json['briefing_id'] ?? json['briefingId'] ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      date: json['date'] ?? '',
      periodStart: json['period_start'] ?? json['periodStart'] ?? '',
      periodEnd: json['period_end'] ?? json['periodEnd'] ?? '',
      totalChecks: json['total_checks'] ?? json['totalChecks'] ?? 0,
      totalFindings: json['total_findings'] ?? json['totalFindings'] ?? 0,
      totalCostUsdc: parseDouble(json['total_cost_usdc'] ?? json['totalCostUsdc'], 0),
      findingsJson: json['findings_json'] ?? json['findingsJson'] ?? [],
      watcherSummaries: ( (json['watcher_summaries_json'] as List?) ?? (json['watcherSummariesJson'] as List?) )
              ?.map((e) => WatcherSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <WatcherSummary>[],
      generatedSummary: json['generated_summary'] ?? json['generatedSummary'],
      isRead: json['read'] == 1 || json['read'] == true,
      generatedAt: json['generated_at'] ?? json['generatedAt'] ?? '',
    );
  }
}

class WalletModel {
  final String publicKey;
  final double balanceUsdc;
  final double balanceXlm;
  final double spentToday;
  final double spentThisWeek;

  const WalletModel({
    required this.publicKey,
    required this.balanceUsdc,
    required this.balanceXlm,
    this.spentToday = 0,
    this.spentThisWeek = 0,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return WalletModel(
      publicKey: json['public_key'] ?? '',
      balanceUsdc: parseDouble(json['balance_usdc'], 0),
      balanceXlm: parseDouble(json['balance_xlm'], 0),
      spentToday: parseDouble(json['spent_today'], 0),
      spentThisWeek: parseDouble(json['spent_this_week'], 0),
    );
  }
}

class TransactionModel {
  final String txId;
  final String userId;
  final String watcherId;
  final String? checkId;
  final double amountUsdc;
  final String serviceName;
  final String stellarTxHash;
  final String timestamp;
  final String? watcherName;
  final bool? findingDetected;

  const TransactionModel({
    required this.txId,
    required this.userId,
    required this.watcherId,
    this.checkId,
    required this.amountUsdc,
    required this.serviceName,
    required this.stellarTxHash,
    required this.timestamp,
    this.watcherName,
    this.findingDetected,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return TransactionModel(
      txId: json['tx_id'] ?? '',
      userId: json['user_id'] ?? '',
      watcherId: json['watcher_id'] ?? '',
      checkId: json['check_id'],
      amountUsdc: parseDouble(json['amount_usdc'], 0),
      serviceName: json['service_name'] ?? '',
      stellarTxHash: json['stellar_tx_hash'] ?? '',
      timestamp: json['timestamp'] ?? '',
      watcherName: json['watcher_name'],
      findingDetected:
          json['finding_detected'] == 1 || json['finding_detected'] == true,
    );
  }
}

class SpendingStatsModel {
  final double? totalSpent;
  final double? spentToday;
  final double? spentThisWeek;
  final List<dynamic>? dailySpending;
  final List<dynamic>? perWatcherSpending;
  final int? totalChecksToday;
  final int? totalFindingsToday;
  final int? totalFindingsAllTime;
  final double? totalSpentAllTime;
  final double? averageCostPerFinding;
  final Map<String, dynamic>? subscriptionComparison;

  const SpendingStatsModel({
    this.totalSpent,
    this.spentToday,
    this.spentThisWeek,
    this.dailySpending,
    this.perWatcherSpending,
    this.totalChecksToday,
    this.totalFindingsToday,
    this.totalFindingsAllTime,
    this.totalSpentAllTime,
    this.averageCostPerFinding,
    this.subscriptionComparison,
  });

  factory SpendingStatsModel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return SpendingStatsModel(
      totalSpent: parseDouble(json['total_spent']),
      spentToday: parseDouble(json['spent_today']),
      spentThisWeek: parseDouble(json['spent_this_week']),
      dailySpending: json['daily_spending'],
      perWatcherSpending: json['per_watcher_spending'],
      totalChecksToday: json['total_checks_today'],
      totalFindingsToday: json['total_findings_today'],
      totalFindingsAllTime: json['total_findings_all_time'],
      totalSpentAllTime: parseDouble(json['total_spent_all_time']),
      averageCostPerFinding: parseDouble(json['average_cost_per_finding']),
      subscriptionComparison: json['subscription_comparison'] is Map 
          ? Map<String, dynamic>.from(json['subscription_comparison']) 
          : null,
    );
  }
}
