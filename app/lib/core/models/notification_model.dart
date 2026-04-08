import 'package:flutter/foundation.dart';

@immutable
class NotificationModel {
  final String notificationId;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? dataId;
  final bool read;
  final DateTime createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.dataId,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notification_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      dataId: json['data_id'] as String?,
      read: json['read'] == 1 || json['read'] == true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'data_id': dataId,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? notificationId,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? dataId,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      dataId: dataId ?? this.dataId,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
