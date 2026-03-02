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
  late final viewmodel = HomeScreenViewmodel();

  @override
  void initState() {
    super.initState();
    viewmodel.loadPets();
  }

  void logout() => FirebaseAuth.instance.signOut();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),

      // Put a Row into the single FAB slot
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // centered area so row can span [web:32]
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.filled(
              onPressed: logout,
              icon: const Icon(Icons.logout, size: 35),
              tooltip: 'Logout',
            ), // IconButton.filled is a Material 3 filled icon button [web:31]

            IconButton.filled(
              onPressed: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPetScreen()),
                );

                if (changed == true) {
                  await viewmodel.loadPets();
                }
              },
              icon: const Icon(Icons.add, size: 35),
              tooltip: 'Add pet',
            ), // IconButton.filled [web:31]
          ],
        ),
      ),

      body: ValueListenableBuilder<List<PetRow>>(
        valueListenable: viewmodel.pets,
        builder: (context, count, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (var i in viewmodel.pets.value.reversed)
                InkWell(
                  child: PetListItem(
                    animalName: i.pet.name,
                    animalType: i.pet.type,
                    animalAge: i.pet.age,
                  ),
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PetDetailScreen(petDocId: i.docId),
                      ),
                    );

                    if (changed == true) {
                      await viewmodel.loadPets();
                    }
                  },
                )
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    viewmodel.dispose();
    super.dispose();
  }
}
