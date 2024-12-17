import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider((ref) => AuthService());

// Create a stream provider for the auth state
final authStateProvider = StreamProvider<AuthState>((ref) {
  print('AuthStateProvider - Initializing');
  final client = Supabase.instance.client;
  
  // Create a stream that starts with the current session state
  final currentSession = client.auth.currentSession;
  print('AuthStateProvider - Current session: $currentSession');
  
  // Emit initial state immediately
  final initialEvent = currentSession != null ? AuthChangeEvent.signedIn : AuthChangeEvent.signedOut;
  return Stream.value(AuthState(initialEvent, currentSession)).asyncExpand((_) {
    // Then continue with the regular auth state changes
    return client.auth.onAuthStateChange.map((state) {
      print('AuthStateProvider - Auth state changed:');
      print('  Event type: ${state.event}');
      print('  Session: ${state.session}');
      print('  User: ${state.session?.user}');
      return state;
    });
  });
});

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    print('AuthService - Signing up user: $email');
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    print('AuthService - Sign up response: $response');
    if (response.user != null) {
      // Create user profile in the profiles table
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'username': username,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    print('AuthService - Signing in user: $email');
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    print('AuthService - Sign in response: $response');
    return response;
  }

  Future<void> signOut() async {
    print('AuthService - Signing out user');
    await _supabase.auth.signOut();
    print('AuthService - User signed out');
  }

  Future<void> resetPassword(String email) async {
    print('AuthService - Resetting password for: $email');
    await _supabase.auth.resetPasswordForEmail(email);
    print('AuthService - Password reset email sent');
  }
}
