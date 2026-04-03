import 'package:ghost_app/features/findings/data/models/finding_model.dart';

class WatcherSummary {
  final String watcherId;
  final String watcherName;
  final int checksRun;
  final int findingsCount;
  final double spent;
  final String latestDataSummary;

  const WatcherSummary({
    required this.watcherId,
    required this.watcherName,
    required this.checksRun,
    required this.findingsCount,
    required this.spent,
    required this.latestDataSummary,
  });

  factory WatcherSummary.fromJson(Map<String, dynamic> json) {
    return WatcherSummary(
      watcherId: json['watcherId'] as String,
      watcherName: json['watcherName'] as String,
      checksRun: json['checksRun'] as int? ?? 0,
      findingsCount: json['findingsCount'] as int? ?? 0,
      spent: (json['spent'] as num? ?? 0.0).toDouble(),
      latestDataSummary: json['latestDataSummary'] as String? ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'watcherId': watcherId,
      'watcherName': watcherName,
      'checksRun': checksRun,
      'findingsCount': findingsCount,
      'spent': spent,
      'latestDataSummary': latestDataSummary,
    };
  }

  WatcherSummary copyWith({
    String? watcherId,
    String? watcherName,
    int? checksRun,
    int? findingsCount,
    double? spent,
    String? latestDataSummary,
  }) {
    return WatcherSummary(
      watcherId: watcherId ?? this.watcherId,
      watcherName: watcherName ?? this.watcherName,
      checksRun: checksRun ?? this.checksRun,
      findingsCount: findingsCount ?? this.findingsCount,
      spent: spent ?? this.spent,
      latestDataSummary: latestDataSummary ?? this.latestDataSummary,
    );
  }
}

class BriefingModel {
  final String briefingId;
  final String userId;
  final String date;
  final int totalChecks;
  final int totalFindings;
  final double totalCostUsdc;
  final List<FindingModel> findings;
  final List<WatcherSummary> watcherSummaries;
  final String generatedSummary;
  final bool read;
  final DateTime generatedAt;

  const BriefingModel({
    required this.briefingId,
    required this.userId,
    required this.date,
    required this.totalChecks,
    required this.totalFindings,
    required this.totalCostUsdc,
    required this.findings,
    required this.watcherSummaries,
    required this.generatedSummary,
    this.read = false,
    required this.generatedAt,
  });

  factory BriefingModel.fromJson(Map<String, dynamic> json) {
    return BriefingModel(
      briefingId: json['briefingId'] as String,
      userId: json['userId'] as String,
      date: json['date'] as String,
      totalChecks: json['totalChecks'] as int? ?? 0,
      totalFindings: json['totalFindings'] as int? ?? 0,
      totalCostUsdc: (json['totalCostUsdc'] as num? ?? 0.0).toDouble(),
      findings: (json['findings'] as List<dynamic>?)
              ?.map((e) => FindingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      watcherSummaries: (json['watcherSummaries'] as List<dynamic>?)
              ?.map((e) => WatcherSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      generatedSummary: json['generatedSummary'] as String? ?? "",
      read: json['read'] as bool? ?? false,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'briefingId': briefingId,
      'userId': userId,
      'date': date,
      'totalChecks': totalChecks,
      'totalFindings': totalFindings,
      'totalCostUsdc': totalCostUsdc,
      'findings': findings.map((e) => e.toJson()).toList(),
      'watcherSummaries': watcherSummaries.map((e) => e.toJson()).toList(),
      'generatedSummary': generatedSummary,
      'read': read,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  BriefingModel copyWith({
    String? briefingId,
    String? userId,
    String? date,
    int? totalChecks,
    int? totalFindings,
    double? totalCostUsdc,
    List<FindingModel>? findings,
    List<WatcherSummary>? watcherSummaries,
    String? generatedSummary,
    bool? read,
    DateTime? generatedAt,
  }) {
    return BriefingModel(
      briefingId: briefingId ?? this.briefingId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      totalChecks: totalChecks ?? this.totalChecks,
      totalFindings: totalFindings ?? this.totalFindings,
      totalCostUsdc: totalCostUsdc ?? this.totalCostUsdc,
      findings: findings ?? this.findings,
      watcherSummaries: watcherSummaries ?? this.watcherSummaries,
      generatedSummary: generatedSummary ?? this.generatedSummary,
      read: read ?? this.read,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
