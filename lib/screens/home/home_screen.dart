import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/bucks_companion.dart';

/// Placeholder Home Dashboard. Real content (balance, budget progress,
/// missions, etc.) comes later — for now this doubles as a navigation
/// hub so every screen is reachable, and shows a small example of
/// `provider` in action via [AppStateProvider].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // `context.watch` rebuilds this widget whenever AppStateProvider
    // calls notifyListeners().
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BucksCompanion(
                message:
                    'Welcome back, ${appState.username}! You have ${appState.buckPoints} Bucks points.',
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => appState.addPoints(10),
                child: const Text('+10 points (demo of provider)'),
              ),
              const SizedBox(height: 16),
              Text('Go to:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _NavCard('Transactions', Icons.receipt_long, Routes.transactions),
                    _NavCard('Budget', Icons.pie_chart, Routes.budget),
                    _NavCard('Savings', Icons.savings, Routes.savings),
                    _NavCard('Reports', Icons.bar_chart, Routes.reports),
                    _NavCard('Missions', Icons.flag, Routes.missions),
                    _NavCard('BucksBoard', Icons.leaderboard, Routes.bucksboard),
                    _NavCard('Profile', Icons.person, Routes.profile),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small reusable card used only on this screen for now. Receives its
/// data via constructor, per the project's widget rules.
class _NavCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;

  const _NavCard(this.label, this.icon, this.route);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
