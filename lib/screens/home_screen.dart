
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    viewmodel.getPetCount(); // should update petCount.value inside the viewmodel
  }

  void logout() => FirebaseAuth.instance.signOut();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ValueListenableBuilder<int>(
        valueListenable: viewmodel.petCount,
        builder: (context, count, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(count > 0
                  ? 'You have $count pets registered.'
                  : 'No pets registered yet.'),
              const Spacer(),
              ElevatedButton(onPressed: logout, child: const Text('Logout')),
              const Spacer(),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    viewmodel.petCount.dispose(); // only if petCount is created in the viewmodel
    super.dispose();
  }
}

