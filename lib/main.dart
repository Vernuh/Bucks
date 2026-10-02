import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'providers/app_state_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore saved data BEFORE the first frame so no screen ever flashes
  // empty/default values and nothing is reset on startup.
  final appState = AppStateProvider();
  await appState.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateProvider>.value(value: appState),
      ],
      child: const BucksApp(),
    ),
  );
}
