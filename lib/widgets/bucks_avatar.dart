import 'package:flutter/material.dart';

import '../models/bucks_avatar_assets.dart';
import '../models/customization_item.dart';

/// Bucks with whatever is equipped. 
class BucksAvatar extends StatelessWidget {
  static const String assetPath = BucksAvatarAssets.basePath;

  final double size;
  final List<CustomizationItem> equipped;

  const BucksAvatar({
    super.key,
    required this.size,
    this.equipped = const [],
  });

  Widget _fallbackIcon() => Icon(
        Icons.emoji_nature,
        size: size * 1.5,
        color: const Color(0xFF8D5A2B),
      );

  // Try the exact combination first; if the file is missing, step down to
  // the closest valid asset, ending at bucks_base.png.
  Widget _image(List<String> candidates, int index) {
    if (index >= candidates.length) return _fallbackIcon();
    final path = candidates[index];
    return Image.asset(
      path,
      key: ValueKey(path),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => _image(candidates, index + 1),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _image(BucksAvatarAssets.candidatesFor(equipped), 0);
}
