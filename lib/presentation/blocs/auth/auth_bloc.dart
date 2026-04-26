import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../di/service_locator.dart';
import '../../../core/services/pro_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final firebase_auth.FirebaseAuth _auth;

  AuthBloc({firebase_auth.FirebaseAuth? auth})
      : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<SignInWithEmailRequested>(_onSignInWithEmail);
    on<SignUpWithEmailRequested>(_onSignUpWithEmail);
    on<SignOutRequested>(_onSignOut);
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignInWithEmail(
    SignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      await sl<ProService>().identify(cred.user!.uid);
      emit(AuthAuthenticated(cred.user!));
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(_mapError(e.code)));
    } catch (_) {
      emit(const AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onSignUpWithEmail(
    SignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      await cred.user?.updateDisplayName(event.name);
      await sl<ProService>().identify(cred.user!.uid);
      emit(AuthAuthenticated(cred.user!));
    } on firebase_auth.FirebaseAuthException catch (e) {
      emit(AuthError(_mapError(e.code)));
    } catch (_) {
      emit(const AuthError('Something went wrong. Please try again.'));
    }
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _auth.signOut();
    await sl<ProService>().logOut();
    emit(AuthUnauthenticated());
  }

  String _mapError(String code) => switch (code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' ||
        'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' =>
          'An account already exists with this email.',
        'weak-password' => 'Password must be at least 6 characters.',
        'invalid-email' => 'Please enter a valid email address.',
        'too-many-requests' =>
          'Too many attempts. Please try again later.',
        'network-request-failed' => 'Check your internet connection.',
        _ => 'Authentication failed. Please try again.',
      };
}
