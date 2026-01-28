import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:furkeeper/viewmodels/auth.dart';

class LoginViewModel {

  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);
  Future<User?> login(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(email: email, password: password);
      // FirebaseAuth.instance.authStateChanges
      print('User logged in');
    } 
    on TimeoutException {
     print("Auth request timed out (network/throttle).");
     errorMessage.value = "Auth request timed out (network/throttle).";
      } on FirebaseAuthException catch (e) {
        print("FirebaseAuthException ${e.code}: ${e.message}");
        errorMessage.value = e.message;
        if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        errorMessage.value = 'The account already exists for that email.';
      }
      else if (e.code == 'user-not-found') {
        print('No user found for that email.');
        errorMessage.value = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
         errorMessage.value = 'Wrong password provided for that user.';
      }
      }
     catch (e) {
      print(e);
    };
    return null;}

}
