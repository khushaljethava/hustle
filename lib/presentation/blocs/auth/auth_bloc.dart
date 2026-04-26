import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../di/service_locator.dart';
import '../../../core/services/pro_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final firebase_auth.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthBloc({
    firebase_auth.FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']),
        super(AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<SignInWithEmailRequested>(_onSignInWithEmail);
    on<SignUpWithEmailRequested>(_onSignUpWithEmail);
    on<SignInWithGoogleRequested>(_onSignInWithGoogle);
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

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Clear any cached account so a previous failed attempt does not
      // silently return a stale GoogleSignInAccount on the next try.
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(AuthUnauthenticated());
        return;
      }
      final googleAuth = await googleUser.authentication;

      // A null idToken on Android typically indicates a broken Google
      // Sign-In setup — most often a SHA-1 / google-services.json
      // mismatch (e.g. Play App Signing fingerprint not registered).
      if (googleAuth.idToken == null) {
        const diag = 'idToken=null (likely SHA-1 / google-services.json '
            'mismatch — Play App Signing key not registered in Firebase)';
        developer.log('Google sign-in: $diag', name: 'AuthBloc');
        emit(const AuthError(
          'Google sign-in failed. Please try again.',
          diagnostic: diag,
        ));
        return;
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      await sl<ProService>().identify(cred.user!.uid);
      emit(AuthAuthenticated(cred.user!));
    } on firebase_auth.FirebaseAuthException catch (e) {
      final diag = 'FirebaseAuthException code=${e.code} message=${e.message}';
      developer.log('Google sign-in: $diag', name: 'AuthBloc');
      emit(AuthError(_mapError(e.code), diagnostic: diag));
    } on PlatformException catch (e) {
      // PlatformException.code == 'sign_in_failed' with details containing
      // 'ApiException: 10' is the canonical SHA-1 / DEVELOPER_ERROR
      // signature. 12500 = SIGN_IN_FAILED, 12501 = cancelled, 7 = network.
      final diag = 'PlatformException code=${e.code} '
          'message=${e.message} details=${e.details}';
      developer.log('Google sign-in: $diag', name: 'AuthBloc');
      if (e.code == 'sign_in_canceled' || e.code == 'sign_in_cancelled') {
        emit(AuthUnauthenticated());
      } else {
        emit(AuthError(_mapGoogleError(e.code), diagnostic: diag));
      }
    } catch (e, stackTrace) {
      final diag = '${e.runtimeType}: $e';
      developer.log(
        'Google sign-in unexpected: $diag',
        name: 'AuthBloc',
        error: e,
        stackTrace: stackTrace,
      );
      emit(AuthError(
        'Google sign-in failed. Please try again.',
        diagnostic: diag,
      ));
    }
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await sl<ProService>().logOut();
    emit(AuthUnauthenticated());
  }

  String _mapGoogleError(String code) => switch (code) {
        'network_error' => 'Check your internet connection.',
        'sign_in_failed' => 'Google sign-in failed. Please try again.',
        _ => 'Google sign-in failed. Please try again.',
      };

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
