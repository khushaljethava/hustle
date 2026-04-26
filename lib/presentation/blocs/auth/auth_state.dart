part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final firebase_auth.User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user.uid];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  // Technical detail for diagnosing production failures (e.g. the
  // PlatformException.code + details). Surfaced on the login screen via
  // a "Copy" SnackBarAction so testers can report the real error code
  // without needing adb logcat.
  final String? diagnostic;

  const AuthError(this.message, {this.diagnostic});

  @override
  List<Object?> get props => [message, diagnostic];
}
