import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:furkeeper/viewmodels/auth.dart';

class RegisterViewmodel {
  final FirebaseAuth _auth = auth;

    
  Future<void> register(String email, String password) async {
      print("before: ${_auth.currentUser?.uid} ${_auth.currentUser?.email}");

    try {
      _auth.signOut();
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      print('User registered successfully');
    }
    

     on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('The email is already in use.');

      } else if (e.code == 'weak-password') {
        print('The password is too weak.');
      } else {
        print('Error: ${e.message}');
      }
    } 
    
    catch (e) {
      print('Error: $e');
      rethrow;
    }
    print("after: ${_auth.currentUser?.uid} ${_auth.currentUser?.email}");
  }
}