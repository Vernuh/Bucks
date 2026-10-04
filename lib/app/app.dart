import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'auth_gate.dart';
import 'routes.dart';

/// The root widget of BUCKS. Sets up the theme and routing.

class BucksApp extends StatelessWidget {
  const BucksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BUCKS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      routes: Routes.all,
    );
  }
}