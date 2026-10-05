import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'providers/app_state_provider.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // make sure flutter is up

  // 1. Initialize Supabase.
  try {
    await SupabaseService.initialize();
  } catch (e) {
    runApp(_StartupErrorApp(message: '$e'));
    return;
  }

  // 2. Restore the existing Supabase session (if any) and load that user's data. The UI shows a loading screen until this finishes.
  final appState = AppStateProvider();
  appState.restoreSession(); // meron na bang loging session yung user?

  runApp( // app running
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateProvider>.value(value: appState),
      ],
      child: const BucksApp(),
    ),
  );
}

/// Shown only when the app cannot start (e.g. Supabase not configured).
class _StartupErrorApp extends StatelessWidget {
  final String message;
  const _StartupErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              message.replaceFirst('Bad state: ', ''),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
