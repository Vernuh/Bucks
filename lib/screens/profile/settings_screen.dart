import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state_provider.dart';

/// Edit the display name, reset account data, and (debug builds only) set
/// the Bucks Coins balance for testing purchases.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<AppStateProvider>().username,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmReset() async {
    final app = context.read<AppStateProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This deletes your transactions, goals, budgets, Bucks Coins, XP '
          'and customization from your account. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await app.resetAllData();
    if (!mounted) return;
    _nameController.text = app.username;
    _toast(result.message);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Display name',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Your name'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.trim().isEmpty) {
                    _toast('Enter a name.');
                    return;
                  }
                  context
                      .read<AppStateProvider>()
                      .setUsername(_nameController.text);
                  _toast('Name updated.');
                },
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _confirmReset,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Reset all data'),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 32),
            Text('Developer tools (debug builds only)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Bucks Coins now: ${app.buckCoins}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final amount in const [0, 30, 150, 500])
                  OutlinedButton(
                    onPressed: () => context
                        .read<AppStateProvider>()
                        .debugSetBuckCoins(amount),
                    child: Text('Set to $amount'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
