import 'package:equatable/equatable.dart';

/// Authentication Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check current auth status on app start
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User initiated Google Sign-In
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// User requested sign out
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// User requested account deletion
class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}
