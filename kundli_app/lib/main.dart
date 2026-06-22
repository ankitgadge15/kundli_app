import 'package:flutter/material.dart';
import 'screens/birth_details_screen.dart';

void main() {
  runApp(const KundliApp());
}

class KundliApp extends StatelessWidget {
  const KundliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SCS Kundli App',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const BirthDetailsScreen(),
    );
  }
}