import 'package:flutter/material.dart';

import 'home/home_screen.dart';
import 'bucks/bucks_screen.dart';
import 'transactions/add_transaction_screen.dart';
import 'savings/savings_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/main_nav_bar.dart';

/// This isn't inside a feature folder like the other screens — it's a
/// shell that *wraps* 5 of them (Home, Bucks, Add, Goals, Profile)
/// behind one persistent bottom nav bar, matching your mockup.
///
/// The tab index (_index) is ephemeral UI state that only this widget
/// cares about, so a plain StatefulWidget + setState is the right tool
/// here — no need to put it in a Provider.
///
/// Note: "Goals" currently shows the Savings screen placeholder. Per
/// your mockup, Goals will eventually also surface Budget Planner and
/// Reports — we'll build that out when we get to the Goals tab.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // IndexedStack keeps all 5 tabs alive in memory (rather than
  // rebuilding them each time you switch tabs), so state like scroll
  // position is preserved.
  final List<Widget> _tabs = const [
    HomeScreen(),
    BucksScreen(),
    AddTransactionScreen(),
    SavingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: MainNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
