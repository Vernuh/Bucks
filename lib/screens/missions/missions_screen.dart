import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mission.dart';
import '../../providers/app_state_provider.dart';

/// Today's three missions. Completion happens automatically when the user
/// really does the action (log an expense, save money, open Reports...) —
/// there is nothing to tick here.
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  static const _blue = Color(0xFF1688F5);
  static const _navy = Color(0xFF17213F);
  static const _green = Color(0xFF218B0D);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final missions = app.missions;
    final done = missions.where((m) => m.isCompleted).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Missions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$done / ${missions.length} completed today',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Level ${app.level} \u2022 ${app.xp} XP',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Color(0xFFFFD21F)),
                    const SizedBox(width: 4),
                    Text(
                      '${app.currentStreak} day streak',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final m in missions) _missionCard(m),
          const SizedBox(height: 8),
          Text(
            'New missions appear every day.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _missionCard(Mission m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: m.isCompleted ? const Color(0xFFEAF7E6) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: m.isCompleted ? _green : const Color(0xFFE6E1D3)),
      ),
      child: Row(
        children: [
          Icon(
            m.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: m.isCompleted ? _green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.title,
                  style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.bold,
                    decoration:
                        m.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(m.description,
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${m.bucksReward} Bucks',
                  style: const TextStyle(
                      color: _blue, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('+${m.xpReward} XP',
                  style: const TextStyle(
                      color: Color(0xFFFFA726),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
