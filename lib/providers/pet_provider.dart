import 'package:flutter/material.dart';
import 'package:furkeeper/models/pet.dart';

class PetProvider with ChangeNotifier {
  final List<Pet> _pets = [];

  List<Pet> get pets => [..._pets];

  void addPet(Pet pet) {
    _pets.add(pet);
    notifyListeners();
  }

  void removePet(String id) {
    _pets.removeWhere((pet) => pet.id == id);
    notifyListeners();
  }

  void updatePet(String id, Pet updatedPet) {
    final petIndex = _pets.indexWhere((pet) => pet.id == id);
    if (petIndex >= 0) {
      _pets[petIndex] = updatedPet;
      notifyListeners();
    }
  }

  Pet? findById(String id) {
    return _pets.firstWhere((pet) => pet.id == id);
  }
}