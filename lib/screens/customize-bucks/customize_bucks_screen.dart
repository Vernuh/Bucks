import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customization_item.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/bucks_avatar.dart';

/// Customize Bucks: buy and equip outfits, hats and accessories.

class CustomizeBucksScreen extends StatelessWidget {
  const CustomizeBucksScreen({super.key});

  static const Color _blue = Color(0xFF1688F5);
  static const Color _yellow = Color(0xFFFFD21F);
  static const Color _navy = Color(0xFF17213F);
  static const Color _green = Color(0xFF218B0D);

  void _onTap(BuildContext context, CustomizationItem item) {
    final app = context.read<AppStateProvider>();
    final ActionResult result;

    if (app.isCustomizationEquipped(item.id)) {
      result = app.unequipCustomizationItem(item.id);
    } else if (app.isCustomizationUnlocked(item.id)) {
      result = app.equipCustomizationItem(item.id);
    } else {
      result = app.purchaseCustomizationItem(item.id);
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: const Text(
          'Customize Bucks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _preview(app.buckCoins, app.equippedItems),
              for (final category in CustomizationCatalog.categories) ...[
                const SizedBox(height: 24),
                Text(
                  category,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _grid(context, app, category),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(int balance, List<CustomizationItem> equipped) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 140,
              height: 20,
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: BucksAvatar(size: 180, equipped: equipped),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Bucks',
          style: TextStyle(
            color: _navy,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          equipped.isEmpty
              ? 'Nothing equipped yet'
              : 'Equipped: ${equipped.map((i) => i.name).join(', ')}\n'
                  'Tap an equipped item to unequip it.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _navy, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on, color: _yellow, size: 20),
              const SizedBox(width: 6),
              Text(
                '$balance Bucks',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _grid(BuildContext context, AppStateProvider app, String category) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      // Tall enough for icon + 2-line name + price + button on small phones.
      childAspectRatio: 0.62,
      children: [
        for (final item in CustomizationCatalog.inCategory(category))
          _itemCard(context, app, item),
      ],
    );
  }

  Widget _itemCard(
    BuildContext context,
    AppStateProvider app,
    CustomizationItem item,
  ) {
    final unlocked = app.isCustomizationUnlocked(item.id);
    final equipped = app.isCustomizationEquipped(item.id);
    final label = equipped ? 'Equipped \u2713' : (unlocked ? 'Equip' : 'Buy');

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: equipped ? _green : const Color(0xFFE6E1D3),
          width: equipped ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 56,
            width: double.infinity,
            child: Image.asset(
              item.imagePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, _, _) =>
                  Icon(item.icon, size: 34, color: _blue),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, color: _yellow, size: 14),
              const SizedBox(width: 3),
              Text(
                '${item.cost}',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: ElevatedButton(
              onPressed: () => _onTap(context, item),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: equipped
                    ? _green
                    : (unlocked ? _blue : _yellow),
                foregroundColor: (equipped || unlocked) ? Colors.white : _navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: FittedBox(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
