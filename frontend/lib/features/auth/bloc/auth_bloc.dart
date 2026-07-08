import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AppAuthState> {
  final SupabaseClient _supabaseClient;

  AuthBloc({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient,
        super(AuthInitial()) {
    on<AuthInitialize>(_onInitialize);
    on<AuthSignUp>(_onSignUp);
    on<AuthSignIn>(_onSignIn);
    on<AuthSignOut>(_onSignOut);
  }

  void _onInitialize(AuthInitialize event, Emitter<AppAuthState> emit) {
    final session = _supabaseClient.auth.currentSession;
    if (session != null) {
      emit(AuthAuthenticated(session.user));
    } else {
      emit(AuthUnauthenticated());
    }
    
    // We could listen to auth state changes, but typically it's handled via a StreamSubscription outside or within the Bloc if needed.
  }

  Future<void> _onSignUp(AuthSignUp event, Emitter<AppAuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _supabaseClient.auth.signUp(
        email: event.email,
        password: event.password,
        data: {
          'company_name': event.companyName,
        }
      );
      if (response.user != null) {
        emit(AuthAuthenticated(response.user!));
      } else {
        emit(const AuthFailure('Sign up failed. Please try again.'));
      }
    } on AuthException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignIn(AuthSignIn event, Emitter<AppAuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      if (response.user != null) {
        emit(AuthAuthenticated(response.user!));
      } else {
        emit(const AuthFailure('Login failed.'));
      }
    } on AuthException catch (e) {
      emit(AuthFailure(e.message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AppAuthState> emit) async {
    emit(AuthLoading());
    try {
      await _supabaseClient.auth.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
