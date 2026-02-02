import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:furkeeper/models/pet.dart';
import 'package:furkeeper/viewmodels/db.dart';

class HomeScreenViewmodel {
  HomeScreenViewmodel(){
    loadPets();

  }
  final userPets = db.collection('pets').doc('pets');
  final ValueNotifier<List<Pet>> pets = ValueNotifier<List<Pet>>([]);
  final petCount = ValueNotifier<int>(0);
   Future<void> loadPets() async {
    final snap = await db
        .collection('pets')
        .orderBy('id') 
        .get();

    pets.value = snap.docs
        .map((doc) => Pet.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
  
  Future<void> addPet(String name, String type, int age) async {
    final counterRef = db.collection('_counters').doc('pets');
   
   
  

    await db.runTransaction((transaction) async {
      final counterSnap = await transaction.get(counterRef); // [web:33]

      final current = (counterSnap.data()?['nextId'] as int?) ?? 0;
      final nextId = current + 1;

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

 
}
