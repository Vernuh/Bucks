import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../providers/app_state_provider.dart';

/// The Profile ("Account") tab: header, Bucks + profile picture row,
/// a dark summary card, a "View history" button, and Settings/Sign Out
/// buttons.
///
/// Most of this is sample data for now — AppStateProvider only has
/// `username` and `buckPoints`, not level/savings/expenses, so those
/// stay hardcoded until real storage exists. `username` IS reused here
/// (via context.watch) since it's already a real field, unlike the
/// others.
///
/// Bucks' character reuses the same Icons.emoji_nature placeholder the
/// Home and Bucks tabs already use, for visual consistency, without
/// touching BucksCompanion's file. There's no real profile photo asset
/// either, so that's an Icons.person placeholder.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _blue = Color(0xFF1688F5);
  static const _yellow = Color(0xFFFFD21F);
  static const _darkNavy = Color(0xFF17213F);
  static const _darkBlueCard = Color(0xFF07579F);
  static const _green = Color(0xFF218B0D);
  static const _gray = Color(0xFF777777);

  // Sample data — level/savings/expenses aren't tracked in
  // AppStateProvider yet.
  static const String _summaryLevel = 'Level 00';
  static const String _totalSavings = 'Php 99999';
  static const String _totalExpenses = 'Php 99999';

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
              const _ProfileHeader(blue: _blue, yellow: _yellow),
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
                  level: _summaryLevel,
                  savings: _totalSavings,
                  expenses: _totalExpenses,
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Sign out coming soon!')));
    }
  }
}

/// Bright blue header: "BUCKS" (gold, left), "Level 17" (white, right),
/// thin yellow progress bar along the bottom. Matches the style used
/// on the Home and Bucks tabs, rebuilt locally here since there's no
/// shared header widget to import without creating a new file.
class _ProfileHeader extends StatelessWidget {
  final Color blue;
  final Color yellow;

  const _ProfileHeader({required this.blue, required this.yellow});

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
                'Level 17',
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
              value: 0.6, // placeholder — no real XP/level data yet
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
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(
                Icons.emoji_nature,
                size: 80,
                color: Color(0xFF8D5A2B),
              ),
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

/// Dark blue rounded card showing Current Level / Total Savings /
/// Total Expenses — labels in gold, values in white.
class _ProfileSummaryCard extends StatelessWidget {
  final Color cardColor;
  final Color yellow;
  final String level;
  final String savings;
  final String expenses;

  const _ProfileSummaryCard({
    required this.cardColor,
    required this.yellow,
    required this.level,
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
