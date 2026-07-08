import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthInitialize extends AuthEvent {}

class AuthSignUp extends AuthEvent {
  final String email;
  final String password;
  final String companyName;

  const AuthSignUp({
    required this.email,
    required this.password,
    required this.companyName,
  });

  @override
  List<Object> get props => [email, password, companyName];
}

class AuthSignIn extends AuthEvent {
  final String email;
  final String password;

  const AuthSignIn({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthSignOut extends AuthEvent {}
