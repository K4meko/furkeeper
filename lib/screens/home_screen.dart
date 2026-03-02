import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:furkeeper/models/pet.dart';
import 'package:furkeeper/screens/add_pet_screen.dart';
import 'package:furkeeper/screens/components/pet_list_item.dart';
import 'package:furkeeper/screens/pet_detail.dart';
import 'package:furkeeper/viewmodels/homescreenviewmodel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeScreenViewmodel viewmodel = HomeScreenViewmodel();

  @override
  void initState() {
    super.initState();
    viewmodel.loadPets();
  }

  void logout() => FirebaseAuth.instance.signOut();

  Future<void> _openAddPet() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddPetScreen()),
    );

    if (changed == true) {
      await viewmodel.loadPets();
    }
  }

  Future<void> _openPetDetail(String docId) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PetDetailScreen(petDocId: docId)),
    );

    if (changed == true) {
      await viewmodel.loadPets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // supported Scaffold location [web:20]
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.filled(
              onPressed: logout,
              icon: const Icon(Icons.logout, size: 35),
              tooltip: 'Logout',
            ), // filled variant exists in Material 3 [web:22]
            IconButton.filled(
              onPressed: _openAddPet,
              icon: const Icon(Icons.add, size: 35),
              tooltip: 'Add pet',
            ), // filled variant exists in Material 3 [web:22]
          ],
        ),
      ),
      body: ValueListenableBuilder<List<PetRow>>(
        valueListenable: viewmodel.pets,
        builder: (context, pets, _) {
          if (pets.isEmpty) {
            return const Center(
              child: Text('No pets yet'),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (final row in pets.reversed)
                InkWell(
                  onTap: () => _openPetDetail(row.docId),
                  child: PetListItem(
                    animalName: row.pet.name,
                    animalType: row.pet.type,
                    animalAge: row.pet.age,
                  ),
                ),
            ],
          );
        },
      ), // ValueListenableBuilder rebuilds when the ValueListenable changes [web:14]
    );
  }

  @override
  void dispose() {
    viewmodel.dispose();
    super.dispose();
  }
}
