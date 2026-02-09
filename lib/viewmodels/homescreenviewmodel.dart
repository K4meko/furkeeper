import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:furkeeper/models/pet.dart';
import 'package:furkeeper/viewmodels/db.dart';

class PetRow {
  final String docId;
  final Pet pet;
  PetRow({required this.docId, required this.pet});
}

class HomeScreenViewmodel {
  final ValueNotifier<List<PetRow>> pets = ValueNotifier<List<PetRow>>([]);
  final ValueNotifier<int> petCount = ValueNotifier<int>(0);

  Future<void> loadPets() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      pets.value = [];
      petCount.value = 0;
      return;
    }

    final snap = await db
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .orderBy('id')
        .get();

    final list = snap.docs
        .map((d) => PetRow(docId: d.id, pet: Pet.fromMap(d.data())))
        .toList();

    pets.value = list;
    petCount.value = list.length;
  }

  void dispose() {
    pets.dispose();
    petCount.dispose();
  }
}
