import 'package:flutter/material.dart';
import '../../app/routes.dart';

/// This wasn't in the original folder skeleton — it's new based on
/// your "Bucks Page" mockup (level/coins header, big companion,
/// achievements row, Customize Bucks, Bucksboard). Placeholder for now.
class BucksScreen extends StatelessWidget {
  const BucksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bucks')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_nature, size: 64),
            const SizedBox(height: 12),
            const Text('Your Bucks companion lives here.'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, Routes.bucksboard),
              child: const Text('Bucksboard'),
            ),
          ],
        ),
      ),
    );
  }
}
