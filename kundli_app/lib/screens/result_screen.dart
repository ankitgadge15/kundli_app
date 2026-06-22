import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String name;
  final String dob;
  final String birthTime;
  final String place;

  const ResultScreen({
    super.key,
    required this.name,
    required this.dob,
    required this.birthTime,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kundli Result"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Name : $name"),
            Text("DOB : $dob"),
            Text("Birth Time : $birthTime"),
            Text("Place : $place"),
          ],
        ),
      ),
    );
  }
}