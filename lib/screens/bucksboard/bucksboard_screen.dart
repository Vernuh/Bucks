import 'package:flutter/material.dart';

class BucksboardScreen extends StatelessWidget {
  const BucksboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BucksBoard')),
      body: const Center(child: Text('Leaderboard coming soon.')),
    );
  }
}
