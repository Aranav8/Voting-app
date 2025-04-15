import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:voting_application/screens/mobile_verification_screen.dart';
import 'package:voting_application/screens/login_screen.dart';
import 'package:voting_application/services/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasData) {
          return MobileVerificationScreen();
        }

        return LoginScreen();
      },
    );
  }
}
