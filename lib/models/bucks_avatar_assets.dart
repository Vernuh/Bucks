import 'customization_item.dart';

/// File pattern: `[outfit]_[hat]_[accessory].png
class BucksAvatarAssets {
  BucksAvatarAssets._();

  static const String basePath = 'assets/bucks/bucks_base.png';

  /// Folder that holds the  combined PNGs 
  static const String directory = 'assets/bucks/customization';

  // item id -> filename token
  static const Map<String, String> _outfitTokens = {
    'outfit_simple': 'simple_outfit',
    'outfit_hoodie': 'hoodie',
    'outfit_fancy': 'fancy_outfit',
  };
  static const Map<String, String> _hatTokens = {
    'hat_simple': 'simple_hat',
    'hat_cap': 'cap',
    'hat_crown': 'crown',
  };
  static const Map<String, String> _accessoryTokens = {
    'acc_sunglasses': 'sunglasses',
    'acc_backpack': 'backpack',
    'acc_golden_glasses': 'golden_glasses',
  };

  /// Builds the file path from whichever parts are present. Returns
  /// [basePath] when nothing at all is equipped.
  static String _path(String? outfit, String? hat, String? acc) {
    final parts = [?outfit, ?hat, ?acc];
    if (parts.isEmpty) return basePath;
    return '$directory/${parts.join('_')}.png';
  }

  /// Asset for the given item ids.
  static String getBucksAvatarAsset({
    String? outfit,
    String? hat,
    String? accessory,
  }) {
    return _path(
      _outfitTokens[outfit],
      _hatTokens[hat],
      _accessoryTokens[accessory],
    );
  }

  /// Same thing, from the provider's equipped list.
  static String forEquipped(List<CustomizationItem> equipped) =>
      getBucksAvatarAsset(
        outfit: _idIn(equipped, CustomizationCatalog.outfits),
        hat: _idIn(equipped, CustomizationCatalog.hats),
        accessory: _idIn(equipped, CustomizationCatalog.accessories),
      );

  /// Closest-first list of assets to try if a file fails to load
  static List<String> candidatesFor(List<CustomizationItem> equipped) {
    final outfit = _outfitTokens[_idIn(equipped, CustomizationCatalog.outfits)];
    final hat = _hatTokens[_idIn(equipped, CustomizationCatalog.hats)];
    final acc =
        _accessoryTokens[_idIn(equipped, CustomizationCatalog.accessories)];
    final out = <String>[];
    void add(String p) {
      if (!out.contains(p)) out.add(p);
    }

    add(_path(outfit, hat, acc));
    if (hat != null) add(_path(outfit, hat, null));
    if (acc != null) add(_path(outfit, null, acc));
    if (outfit != null) add(_path(outfit, null, null));
    add(basePath);
    return out;
  }

  /// All combined assets (3 outfits x 4 hats x 4 accessories).
  static List<String> get allCombinationAssets => [
        for (final o in _outfitTokens.values)
          for (final h in [null, ..._hatTokens.values])
            for (final a in [null, ..._accessoryTokens.values])
              _path(o, h, a),
      ];

  static String? _idIn(List<CustomizationItem> items, String category) {
    for (final i in items) {
      if (i.category == category) return i.id;
    }
    return null;
  }
}
