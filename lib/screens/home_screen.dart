
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:furkeeper/models/pet.dart';
import 'package:furkeeper/screens/components/pet_list_item.dart';
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
   // should update petCount.value inside the viewmodel
  }

  void logout() => FirebaseAuth.instance.signOut();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      floatingActionButton: IconButton.filled(onPressed: (){}, icon: Icon(Icons.add, size: 35,)),
      body: ValueListenableBuilder<List<Pet>>(
        valueListenable: viewmodel.pets,
        builder: (context, count, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Text(count > 0
              //     ? 'You have $count pets registered.'
              //     : 'No pets registered yet.'),
              // const Spacer(),
              // ElevatedButton(onPressed: logout, child: const Text('Logout')),
              // const Spacer(),
              for( var i in viewmodel.pets.value) PetListItem(animalName: i.name, animalType: i.type, animalAge: i.age)
          ]);
        }
      ),
    );
  }

  @override
  void dispose() {
    viewmodel.petCount.dispose(); // only if petCount is created in the viewmodel
    super.dispose();
  }
}

