import 'package:hive_flutter/hive_flutter.dart';

abstract class AuthLocalDataSource {
  Future<String?> getUserId();
  Future<void> cacheUserId(String userId);
  Future<void> clear();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box _box;
  static const String _userIdKey = 'user_id';

  AuthLocalDataSourceImpl(this._box);

  @override
  Future<String?> getUserId() async {
    return _box.get(_userIdKey);
  }

  @override
  Future<void> cacheUserId(String userId) async {
    await _box.put(_userIdKey, userId);
  }

  @override
  Future<void> clear() async {
    await _box.delete(_userIdKey);
  }
}
