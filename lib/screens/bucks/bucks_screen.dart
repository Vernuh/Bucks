import 'package:flutter/material.dart';
import '../../app/routes.dart';

class BucksScreen extends StatelessWidget {
  const BucksScreen({super.key});

  static const Color _blue = Color(0xFF1688F5);
  static const Color _darkNavy = Color(0xFF17213F);
  static const Color _gold = Color(0xFFFFD21F);
  static const Color _groundGreen = Color(0xFF218B0D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _blue,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER
              const _BucksHeader(),

              // BUCKS CHARACTER
              const _BucksCharacter(),

              // BUCKS MESSAGE
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: _BucksMessage(
                  text: "Bawk! Let's keep those finances cluckin'!",
                ),
              ),

              // ACHIEVEMENTS + CHAT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Stack the cards on smaller screens.
                    if (constraints.maxWidth < 500) {
                      return Column(
                        children: [
                          _AchievementsCard(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.achievements);
                            },
                          ),
                          const SizedBox(height: 12),
                          _ChatCard(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.chat);
                            },
                          ),
                        ],
                      );
                    }

                    // Keep them side-by-side on wider screens.
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _AchievementsCard(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.achievements);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _ChatCard(
                            onTap: () {
                              Navigator.pushNamed(context, Routes.chat);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // CUSTOMIZE BUCKS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _BucksFeatureCard(
                  blue: _blue,
                  icon: Icons.checkroom,
                  title: 'Customize Bucks',
                  description:
                      'Customize Bucks with unlockable outfits, hats, '
                      'and accessories earned through achievements and missions.',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.customizeBucks);
                  },
                ),
              ),

              const SizedBox(height: 12),

              // BUCKSBOARD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _BucksFeatureCard(
                  blue: _blue,
                  icon: Icons.emoji_events,
                  title: 'Bucksboard',
                  description:
                      'See how you rank and compare your progress '
                      'with other Bucks users.',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.bucksboard);
                  },
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// BUCKS HEADER
class _BucksHeader extends StatelessWidget {
  const _BucksHeader();

  static const Color _darkNavy = Color(0xFF17213F);
  static const Color _gold = Color(0xFFFFD21F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _darkNavy,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        children: [
          Row(
            children: [
              // Profile icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 27),
              ),

              const SizedBox(width: 12),

              // Level
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEVEL 17',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Keep going!',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Coins
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on, color: _gold, size: 20),
                    SizedBox(width: 5),
                    Text(
                      '250',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // XP label
          Row(
            children: [
              const Text(
                'XP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '600 / 1000',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // XP bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.60,
              minHeight: 5,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(_gold),
            ),
          ),
        ],
      ),
    );
  }
}

// BUCKS CHARACTER
class _BucksCharacter extends StatelessWidget {
  const _BucksCharacter();

  static const Color _groundGreen = Color(0xFF218B0D);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ground
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              decoration: const BoxDecoration(
                color: _groundGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
            ),
          ),

          // Character placeholder
          Positioned(
            bottom: 18,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🐔', style: TextStyle(fontSize: 72)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// BUCKS MESSAGE
class _BucksMessage extends StatelessWidget {
  final String text;

  const _BucksMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble, color: Color(0xFF1688F5), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF17213F),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CARD SHELL
class _CardShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CardShell({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: card,
      ),
    );
  }
}

// ACHIEVEMENTS CARD
class _AchievementsCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _AchievementsCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFB020),
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Achievements',
                    style: TextStyle(
                      color: Color(0xFF17213F),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _AchievementIcon(icon: Icons.savings, label: 'Saver'),
                _AchievementIcon(icon: Icons.track_changes, label: 'Tracker'),
                _AchievementIcon(icon: Icons.star, label: 'Star'),
                _AchievementIcon(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ACHIEVEMENT ICON
class _AchievementIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AchievementIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4CE),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: const Color(0xFFFFB020), size: 23),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF17213F),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// CHAT CARD
class _ChatCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _ChatCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF1688F5),
                size: 27,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Chat',
              style: TextStyle(
                color: Color(0xFF17213F),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              'Talk to Bucks',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// FEATURE CARD
class _BucksFeatureCard extends StatelessWidget {
  final Color blue;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _BucksFeatureCard({
    required this.blue,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: blue,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: Colors.white, size: 27),
              ),

              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
