import 'package:flutter/material.dart';
import 'package:furkeeper/others/themes.dart';
import 'package:furkeeper/screens/auth/login_screen.dart';
import 'package:furkeeper/screens/home_screen.dart'; // Import your HomeScreen
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:furkeeper/providers/auth_provider.dart';
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
          create: (_) => AuthProvider(storage),
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp(
           debugShowCheckedModeBanner: false,
         theme: AppTheme.lightTheme, // custom light theme
         darkTheme: AppTheme.darkTheme, // custom dark theme
       themeMode: ThemeMode.system, 
          home: authProvider.isAuthenticated ? HomeScreen() : LoginScreen(),
        );
      },
    );
  }
}

