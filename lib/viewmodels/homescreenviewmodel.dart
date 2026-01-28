import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:furkeeper/viewmodels/db.dart';

class HomeScreenViewmodel {

  final userPets = db.collection('pets').doc('pets');
  final petCount = ValueNotifier<int>(0);
  
  Future<void> addPet(String name, String type, int age) async {
    final counterRef = db.collection('_counters').doc('pets');
   
    await db.runTransaction((transaction) async {
      // Read must happen before writes in a transaction.
      final counterSnap = await transaction.get(counterRef); // [web:33]

      final current = (counterSnap.data()?['nextId'] as int?) ?? 0;
      final nextId = current + 1;

      // Update the counter (merge in case doc doesn't exist yet).
      transaction.set(counterRef, {'nextId': nextId}, SetOptions(merge: true));

      // Create the new pet document with the incremented numeric id.
      final petRef = db.collection('pets').doc();
      transaction.set(petRef, {
        'id': nextId,
        'name': name,
        'type': type,
        'age': age,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> getPetCount() async {
    final counterRef = db.collection('_counters').doc('pets');
    final counterSnap = await counterRef.get();
    final current = (counterSnap.data()?['nextId'] as int?) ?? 0;
    petCount.value = current;
  }
}
