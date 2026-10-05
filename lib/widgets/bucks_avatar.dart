import 'package:flutter/material.dart';

class BucksAvatar extends StatelessWidget {
  static const String assetPath = 'assets/bucks/bucks_base.png';

  final double size;

  const BucksAvatar({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => Icon(
        Icons.emoji_nature,
        size: size * 1.5,
        color: const Color(0xFF8D5A2B),
      ),
    );
  }
}
