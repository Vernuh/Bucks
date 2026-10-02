import 'package:flutter/material.dart';

/// A shop item. This is the STATIC catalog entry only — whether it is
/// unlocked or equipped is user state kept by AppStateProvider (as ids),
/// and the Bucks Coins balance lives on the user.
///
/// There are no real Bucks art assets yet, so [icon] is a placeholder.
class CustomizationItem {
  final String id;
  final String name;

  /// One of [CustomizationCatalog.categories]. Only one item per category
  /// can be equipped at a time.
  final String category;
  final int cost;
  final IconData icon;

  const CustomizationItem(
    this.id,
    this.name,
    this.category,
    this.cost,
    this.icon,
  );
}

class CustomizationCatalog {
  CustomizationCatalog._();

  static const String outfits = 'Outfits';
  static const String hats = 'Hats';
  static const String accessories = 'Accessories';

  static const List<String> categories = [outfits, hats, accessories];

  // Same items/ids the Customize Bucks screen already shipped with.
  static const List<CustomizationItem> items = [
    CustomizationItem('outfit_simple', 'Simple Outfit', outfits, 50, Icons.checkroom),
    CustomizationItem('outfit_hoodie', 'Hoodie', outfits, 150, Icons.checkroom),
    CustomizationItem('outfit_fancy', 'Fancy Outfit', outfits, 200, Icons.checkroom),
    CustomizationItem('hat_simple', 'Simple Hat', hats, 50, Icons.emoji_people),
    CustomizationItem('hat_cap', 'Cap', hats, 75, Icons.emoji_people),
    CustomizationItem('hat_crown', 'Crown', hats, 300, Icons.workspace_premium),
    CustomizationItem('acc_sunglasses', 'Sunglasses', accessories, 75, Icons.wb_sunny),
    CustomizationItem('acc_backpack', 'Backpack', accessories, 100, Icons.backpack),
    CustomizationItem('acc_golden_glasses', 'Golden Glasses', accessories, 250, Icons.visibility),
  ];

  static CustomizationItem? byId(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  static List<CustomizationItem> inCategory(String category) =>
      items.where((i) => i.category == category).toList();
}
