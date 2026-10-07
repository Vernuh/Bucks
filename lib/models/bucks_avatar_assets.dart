import 'customization_item.dart';

/// File pattern: `[outfit]_[hat]_[accessory].png`, hat/accessory optional.
class BucksAvatarAssets {
  BucksAvatarAssets._();

  static const String basePath = 'assets/bucks/bucks_base.png';

  /// Folder that holds the 48 combined PNGs (declared in pubspec.yaml).
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

  static String _path(String outfit, String? hat, String? acc) =>
      '$directory/${[outfit, ?hat, ?acc].join('_')}.png';

  /// Asset for the given item ids.
  static String getBucksAvatarAsset({
    String? outfit,
    String? hat,
    String? accessory,
  }) {
    final o = _outfitTokens[outfit];
    if (o == null) return basePath;
    return _path(o, _hatTokens[hat], _accessoryTokens[accessory]);
  }

  /// Same thing, from the provider's equipped list.
  static String forEquipped(List<CustomizationItem> equipped) =>
      getBucksAvatarAsset(
        outfit: _idIn(equipped, CustomizationCatalog.outfits),
        hat: _idIn(equipped, CustomizationCatalog.hats),
        accessory: _idIn(equipped, CustomizationCatalog.accessories),
      );

  /// Closest-first list of assets to try if a file fails to load:
  /// full combo, outfit+hat, outfit+accessory, outfit, base.
  static List<String> candidatesFor(List<CustomizationItem> equipped) {
    final outfit = _outfitTokens[_idIn(equipped, CustomizationCatalog.outfits)];
    if (outfit == null) return const [basePath];
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
    add(_path(outfit, null, null));
    add(basePath);
    return out;
  }

  /// All 48 expected combined assets (3 outfits x 4 hats x 4 accessories).
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
