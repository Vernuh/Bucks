import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'providers/app_state_provider.dart';

void main() {
  runApp(
    // MultiProvider lets us register multiple providers at the top of
    // the widget tree. We only have one right now (AppStateProvider),
    // but this is where TransactionProvider, BudgetProvider, etc. will
    // be added as we build those features.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: const BucksApp(),
    ),
  );
}

