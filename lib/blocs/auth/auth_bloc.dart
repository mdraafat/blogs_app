import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_email_service.dart';
import '../../services/auth_google_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final EmailSignInService _emailService;
  final GoogleSignInService _googleService;

  AuthBloc({
    required EmailSignInService emailService,
    required GoogleSignInService googleService,
  })  : _emailService = emailService,
        _googleService = googleService,
        super(const AuthInitial()) {
    on<AuthEmailSignInRequested>(_onEmailSignIn);
    on<AuthEmailRegisterRequested>(_onEmailRegister);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthSignOutRequested>(_onSignOut);
  }

  Future<void> _onEmailSignIn(
    AuthEmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _emailService.signInWithEmailAndPassword(
        event.email,
        event.password,
      );
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Sign in failed'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_emailService.getErrorMessage(e)));
    } catch (e) {
      emit(const AuthError('An unexpected error occurred'));
    }
  }

  Future<void> _onEmailRegister(
    AuthEmailRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _emailService.registerWithEmailAndPassword(
        event.email,
        event.password,
      );
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Registration failed'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_emailService.getErrorMessage(e)));
    } catch (e) {
      emit(const AuthError('An unexpected error occurred'));
    }
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _googleService.signInWithGoogle();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Google sign in failed'));
      }
    } catch (e) {
      emit(const AuthError('Please try again'));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _emailService.signOut();
    await _googleService.signOut();
    emit(const AuthUnauthenticated());
  }
}