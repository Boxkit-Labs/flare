import 'package:equatable/equatable.dart';
import 'package:ghost_app/core/models/models.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class UserRegistered extends AuthEvent {
  final UserModel user;
  const UserRegistered(this.user);

  @override
  List<Object?> get props => [user];
}

class UpdateUserSettings extends AuthEvent {
  final Map<String, dynamic> settings;
  const UpdateUserSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

class LoggedOut extends AuthEvent {}
