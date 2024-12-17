import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../main.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _showSignUp = false;

  void _toggleAuthScreen() {
    setState(() {
      _showSignUp = !_showSignUp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      return const MainLayout();
    }

    return _showSignUp
        ? SignUpScreen(onLoginTap: _toggleAuthScreen)
        : LoginScreen(onSignUpTap: _toggleAuthScreen);
  }
}
