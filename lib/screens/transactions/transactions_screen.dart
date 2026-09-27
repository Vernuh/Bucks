import 'package:flutter/material.dart';

/// Full transaction history — opened from a button on Home, per your
/// design decision. Adding a new transaction now happens on the "Add"
/// bottom-nav tab rather than a pushed screen from here, so there's no
/// FAB anymore.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: const Center(child: Text('Transaction history coming soon.')),
    );
  }
}
