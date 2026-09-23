import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Placeholder for Bucks, the pixel-art chicken companion.
///
/// This currently just shows a simple circular placeholder with an
/// icon — real pixel-art sprites and expression logic come later,
/// once we have real financial activity for Bucks to react to.
class BucksCompanion extends StatelessWidget {
  final String message;

  const BucksCompanion({
    super.key,
    this.message = "Hi! I'm Bucks. Let's manage your money together!",
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emoji_nature, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}
