import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'routes.dart';

/// The root widget of BUCKS. Sets up the theme and routing.
/// Provider setup happens one level up, in main.dart, so this widget
/// stays focused on just app-level config (theme + routes).
class BucksApp extends StatelessWidget {
  const BucksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BUCKS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: Routes.login,
      routes: Routes.all,
    );
  }
}