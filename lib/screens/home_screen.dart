
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
      floatingActionButton: IconButton.filled(onPressed: () async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddPetScreen()),
    );

    if (changed == true) {
      await viewmodel.loadPets();
    }
  }, icon: Icon(Icons.add, size: 35,)),
      body: ValueListenableBuilder<List<PetRow>>(
        valueListenable: viewmodel.pets,
        builder: (context, count, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Text(count > 0
              //     ? 'You have $count pets registered.'
              //     : 'No pets registered yet.'),
              // const Spacer(),
              // ElevatedButton(onPressed: logout, child: const Text('Logout')),
              // const Spacer(),
              for( var i in viewmodel.pets.value.reversed) 
              InkWell(child: PetListItem(animalName: i.pet.name, animalType: i.pet.type, animalAge: i.pet.age),  onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PetDetailScreen(
            petDocId: i.docId 
          ),
        ),
      );
    }, )
              
          ]);
        }
      ),
    );
  }

  @override
 void dispose() {
  viewmodel.dispose();
  super.dispose();
}
}

