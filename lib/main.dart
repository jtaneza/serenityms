import 'package:flutter/material.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const SerenityApp());
}

class SerenityApp extends StatelessWidget {
  const SerenityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Serenity Admin Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Manrope',
        scaffoldBackgroundColor: const Color(0xFFF4FAFD),
      ),
      home: const LoginPage(),
    );
  }
}