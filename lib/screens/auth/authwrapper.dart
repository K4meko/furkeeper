

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:furkeeper/screens/auth/login_screen.dart';
import 'package:furkeeper/screens/home_screen.dart';

class AuthWrapper extends StatelessWidget{
  const AuthWrapper({super.key});

  @override

  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) { 
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
        if (snapshot.hasData) {
          print("user being redirected to home screen");
          return const HomeScreen();
        }
        return LoginScreen();
      },
    );
  }
}