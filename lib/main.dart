import 'package:flutter/material.dart';
import 'package:furkeeper/providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MultiProvider(providers: 
  [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
  ]
      , child: const MainApp()
  )
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
