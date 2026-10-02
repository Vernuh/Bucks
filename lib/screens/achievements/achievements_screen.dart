import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/achievement.dart';
import '../../providers/app_state_provider.dart';

/// Lists every achievement and whether it is unlocked. Unlock state comes
/// from [AppStateProvider], which grants each reward exactly once.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const _blue = Color(0xFF1688F5);
  static const _navy = Color(0xFF17213F);
  static const _gold = Color(0xFFFFB020);
  static const _green = Color(0xFF218B0D);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text(
          'Achievements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${app.unlockedAchievementCount} / '
              '${AchievementCatalog.all.length} unlocked',
              style: const TextStyle(
                color: _navy,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            for (final def in AchievementCatalog.all)
              _tile(def, app.isAchievementUnlocked(def.id)),
          ],
        ),
      ),
    );
  }

  Widget _tile(AchievementDef def, bool unlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? const Color(0xFFFFF4CE) : const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: unlocked ? _gold : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(def.icon, size: 30, color: unlocked ? _gold : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.name,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  def.description,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reward: +${def.bucksReward} Bucks, +${def.xpReward} XP',
                  style: const TextStyle(color: _blue, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.check_circle : Icons.lock_outline,
            color: unlocked ? _green : Colors.grey,
          ),
        ],
      ),
    );
  }
}
