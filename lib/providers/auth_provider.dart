import 'package:flutter/material.dart';
import 'package:furkeeper/models/user.dart';
import 'package:provider/provider.dart';

class AuthProvider with ChangeNotifier{
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