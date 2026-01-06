import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage storage;

  AuthProvider(this.storage){
    FirebaseAuth.instance.userChanges().listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('User is signed in!');
    }
  });
  }

  User? _user;

  User? get user => _user;

  void login(User user) {
    _user = user;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}