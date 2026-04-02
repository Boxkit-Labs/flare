class UserModel {
  final String userId;
  final String deviceId;
  final String stellarPublicKey;
  final String briefingTime;
  final String timezone;
  final String dndStart;
  final String dndEnd;
  final double? globalDailyCap;
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    required this.deviceId,
    required this.stellarPublicKey,
    this.briefingTime = "07:00",
    this.timezone = "UTC",
    this.dndStart = "23:00",
    this.dndEnd = "07:00",
    this.globalDailyCap,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      deviceId: json['deviceId'] as String,
      stellarPublicKey: json['stellarPublicKey'] as String,
      briefingTime: json['briefingTime'] as String? ?? "07:00",
      timezone: json['timezone'] as String? ?? "UTC",
      dndStart: json['dndStart'] as String? ?? "23:00",
      dndEnd: json['dndEnd'] as String? ?? "07:00",
      globalDailyCap: (json['globalDailyCap'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'stellarPublicKey': stellarPublicKey,
      'briefingTime': briefingTime,
      'timezone': timezone,
      'dndStart': dndStart,
      'dndEnd': dndEnd,
      'globalDailyCap': globalDailyCap,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? userId,
    String? deviceId,
    String? stellarPublicKey,
    String? briefingTime,
    String? timezone,
    String? dndStart,
    String? dndEnd,
    double? globalDailyCap,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      stellarPublicKey: stellarPublicKey ?? this.stellarPublicKey,
      briefingTime: briefingTime ?? this.briefingTime,
      timezone: timezone ?? this.timezone,
      dndStart: dndStart ?? this.dndStart,
      dndEnd: dndEnd ?? this.dndEnd,
      globalDailyCap: globalDailyCap ?? this.globalDailyCap,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
