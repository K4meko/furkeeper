import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetService {
  PetService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<void> savePetForCurrentUser(Map<String, dynamic> petMap) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final userDoc = _db.collection('users').doc(user.uid);

    await userDoc.set({'email': user.email}, SetOptions(merge: true));
    await userDoc.collection('pets').doc().set(petMap);
  }
}
