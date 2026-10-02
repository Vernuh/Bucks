import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';

/// The global leaderboard needs an online backend that doesn't exist yet,
/// so this screen does NOT fake one. It shows an honest empty state plus
/// the user's own stats on this device.
class BucksboardScreen extends StatelessWidget {
  const BucksboardScreen({super.key});

  static const _navy = Color(0xFF17213F);
  static const _blue = Color(0xFF1688F5);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('BucksBoard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'The global leaderboard will be available once BUCKS is '
              'connected online. No rankings are shown yet.',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your stats (this device only)',
            style: TextStyle(
                color: _navy, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _row('Player', app.username),
                _row('Level', '${app.level}'),
                _row('XP', '${app.xp}'),
                _row('Bucks Coins', '${app.buckCoins}'),
                _row('Streak', '${app.currentStreak} days'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFFFFD21F))),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
