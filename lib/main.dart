import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'firebase_options.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   runApp(IntegratourApp());
}

class IntegratourApp extends StatelessWidget {
  const IntegratourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Integratour',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(), // Tela inicial de login
      debugShowCheckedModeBanner: false, // Remove banner de debug
    );
  }
}