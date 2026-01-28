import 'package:flutter/material.dart';
import 'package:furkeeper/others/themes.dart';
import 'package:furkeeper/providers/pet_provider.dart';
import 'package:furkeeper/screens/auth/authwrapper.dart';
// Import your HomeScreen
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  
  final storage = FlutterSecureStorage();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PetProvider(),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PetProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp(
           debugShowCheckedModeBanner: false,
         theme: AppTheme.lightTheme, // custom light theme
         darkTheme: AppTheme.darkTheme, // custom dark theme
       themeMode: ThemeMode.system, 
          home: AuthWrapper(),
        );
      },
    );
  }
}

