import '../../widgets/bucks_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../providers/app_state_provider.dart';
import '../../utils/formatters.dart';

/// The Profile ("Account") tab: header, Bucks + profile picture row, a dark summary card, a "View history" button, and Settings/Sign Out buttons.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _blue = Color(0xFF1688F5);
  static const _yellow = Color(0xFFFFD21F);
  static const _darkNavy = Color(0xFF17213F);
  static const _darkBlueCard = Color(0xFF07579F);
  static const _green = Color(0xFF218B0D);
  static const _gray = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(
                blue: _blue,
                yellow: _yellow,
                level: appState.level,
                progress: appState.levelProgress,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _ProfileCharacterRow(
                  username: appState.username,
                  green: _green,
                  darkNavy: _darkNavy,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _ProfileSummaryCard(
                  cardColor: _darkBlueCard,
                  yellow: _yellow,
                  level: 'Level ${appState.level}',
                  bucks: '${appState.buckCoins}',
                  xp: '${appState.xp}',
                  streak: '${appState.currentStreak} days',
                  savings: 'Php ${formatNumber(appState.totalSaved)}',
                  expenses: 'Php ${formatNumber(appState.totalExpenses)}',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _PrimaryActionButton(
                  label: 'View history',
                  color: _darkBlueCard,
                  onTap: () =>
                      Navigator.pushNamed(context, Routes.transactions),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _SecondaryActionButton(
                        icon: Icons.settings,
                        label: 'Settings',
                        darkNavy: _darkNavy,
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.settings),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SecondaryActionButton(
                        icon: Icons.logout,
                        label: 'Sign Out',
                        darkNavy: _darkNavy,
                        onTap: () => _confirmSignOut(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      // On success AuthGate swaps to Login and the in-memory state is cleared.
      final result = await context.read<AppStateProvider>().signOut();
      if (result.success) {
        navigator.popUntil((route) => route.isFirst);
      } else {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(result.message)));
      }
    }
  }
}

/// Bright blue header: "BUCKS" (gold, left), the real level (white, right), thin yellow XP progress bar along the bottom.
class _ProfileHeader extends StatelessWidget {
  final Color blue;
  final Color yellow;
  final int level;
  final double progress;

  const _ProfileHeader({
    required this.blue,
    required this.yellow,
    required this.level,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      color: blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'BUCKS',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Level $level',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(yellow),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bucks (left, on a green ground shadow) and the profile
/// picture + username (right).
class _ProfileCharacterRow extends StatelessWidget {
  final String username;
  final Color green;
  final Color darkNavy;

  const _ProfileCharacterRow({
    required this.username,
    required this.green,
    required this.darkNavy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 90,
              height: 18,
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: BucksAvatar(size: 150),
            ),
          ],
        ),
        Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: green, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 44, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              username,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: darkNavy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dark blue rounded card showing level, Bucks Coins, XP, streak,
/// savings and expenses — labels in gold, values in white.
class _ProfileSummaryCard extends StatelessWidget {
  final Color cardColor;
  final Color yellow;
  final String level;
  final String bucks;
  final String xp;
  final String streak;
  final String savings;
  final String expenses;

  const _ProfileSummaryCard({
    required this.cardColor,
    required this.yellow,
    required this.level,
    required this.bucks,
    required this.xp,
    required this.streak,
    required this.savings,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Current Level', value: level, yellow: yellow),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Bucks Coins', value: bucks, yellow: yellow),
          const SizedBox(height: 14),
          _SummaryRow(label: 'XP', value: xp, yellow: yellow),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Current Streak', value: streak, yellow: yellow),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Total Savings', value: savings, yellow: yellow),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Total Expenses', value: expenses, yellow: yellow),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color yellow;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.yellow,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: yellow,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Full-width dark blue rounded button ("View history").
class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact dark navy rounded button used for Settings and Sign Out —
/// icon, label, and a trailing chevron.
class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color darkNavy;
  final VoidCallback onTap;

  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.darkNavy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: darkNavy,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
