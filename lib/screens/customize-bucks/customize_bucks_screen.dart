import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';

/// Customize Bucks: buy and equip outfits, hats and accessories.
///
/// All state (balance, unlocked, equipped) lives in [AppStateProvider];
/// this screen only holds the static catalog below.
class CustomizeBucksScreen extends StatelessWidget {
  const CustomizeBucksScreen({super.key});

  static const Color _blue = Color(0xFF1688F5);
  static const Color _yellow = Color(0xFFFFD21F);
  static const Color _navy = Color(0xFF17213F);
  static const Color _green = Color(0xFF218B0D);

  static const List<_Category> _categories = [
    _Category('Outfits', [
      _Item('outfit_simple', 'Simple Outfit', 50, Icons.checkroom),
      _Item('outfit_hoodie', 'Hoodie', 150, Icons.checkroom),
      _Item('outfit_fancy', 'Fancy Outfit', 200, Icons.checkroom),
    ]),
    _Category('Hats', [
      _Item('hat_simple', 'Simple Hat', 50, Icons.emoji_people),
      _Item('hat_cap', 'Cap', 75, Icons.emoji_people),
      _Item('hat_crown', 'Crown', 300, Icons.workspace_premium),
    ]),
    _Category('Accessories', [
      _Item('acc_sunglasses', 'Sunglasses', 75, Icons.wb_sunny),
      _Item('acc_backpack', 'Backpack', 100, Icons.backpack),
      _Item('acc_golden_glasses', 'Golden Glasses', 250, Icons.visibility),
    ]),
  ];

  void _onTap(BuildContext context, _Category cat, _Item item) {
    final app = context.read<AppStateProvider>();
    final messenger = ScaffoldMessenger.of(context);
    String msg;

    if (app.isCustomizationUnlocked(item.id)) {
      if (app.isCustomizationEquipped(cat.name, item.id)) {
        msg = 'Already equipped';
      } else {
        app.equipCustomizationItem(cat.name, item.id);
        msg = '${item.name} equipped!';
      }
    } else if (app.purchaseCustomizationItem(item.id, item.cost)) {
      msg = '${item.name} unlocked!';
    } else {
      msg = 'Not enough Bucks!';
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
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
              _preview(app.buckPoints),
              for (final cat in _categories) ...[
                const SizedBox(height: 24),
                Text(
                  cat.name,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _grid(context, app, cat),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(int balance) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 110,
              height: 20,
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              // Placeholder until real Bucks art exists.
              child: Icon(Icons.pets, size: 90, color: Color(0xFF8D5A2B)),
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

  Widget _grid(BuildContext context, AppStateProvider app, _Category cat) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      // Tall enough for icon + 2-line name + price + button on small phones.
      childAspectRatio: 0.62,
      children: [
        for (final item in cat.items)
          _itemCard(context, app, cat, item),
      ],
    );
  }

  Widget _itemCard(
    BuildContext context,
    AppStateProvider app,
    _Category cat,
    _Item item,
  ) {
    final unlocked = app.isCustomizationUnlocked(item.id);
    final equipped = app.isCustomizationEquipped(cat.name, item.id);
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
          Icon(item.icon, size: 34, color: _blue),
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
              onPressed: () => _onTap(context, cat, item),
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

class _Category {
  final String name;
  final List<_Item> items;
  const _Category(this.name, this.items);
}

class _Item {
  final String id;
  final String name;
  final int cost;
  final IconData icon;
  const _Item(this.id, this.name, this.cost, this.icon);
}
