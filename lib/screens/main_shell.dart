import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mission.dart';
import '../providers/app_state_provider.dart';
import '../widgets/main_nav_bar.dart';
import 'bucks/bucks_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'savings/savings_screen.dart';
import 'transactions/add_transaction_screen.dart';

/// Wraps the 5 main tabs (Home, Bucks, Add, Goals, Profile) behind one
/// persistent bottom nav bar.
///
/// The tab index is ephemeral UI state, so a plain StatefulWidget is the
/// right tool. Everything else comes from [AppStateProvider].
///
/// Entering the shell counts as "opening BUCKS today", opening the Goals
/// tab counts as checking your savings goal, and returning to the app
/// after midnight refreshes the day (new missions, streak).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;

  // IndexedStack keeps all 5 tabs alive so scroll position etc. is kept.
  final List<Widget> _tabs = const [
    HomeScreen(),
    BucksScreen(),
    AddTransactionScreen(),
    SavingsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // After the first frame so we never notify during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppStateProvider>().recordAppOpened();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<AppStateProvider>().recordAppOpened();
    }
  }

  void _onTabTap(int i) {
    setState(() => _index = i);
    if (i == 3) {
      context.read<AppStateProvider>().recordVisit(MissionAction.openGoals);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncError =
        context.select<AppStateProvider, String?>((a) => a.syncError);

    return Scaffold(
      body: Column(
        children: [
          if (syncError != null)
            MaterialBanner(
              content: Text("Couldn't save to your account. $syncError"),
              actions: [
                TextButton(
                  onPressed: () => context.read<AppStateProvider>().retrySync(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(child: IndexedStack(index: _index, children: _tabs)),
        ],
      ),
      bottomNavigationBar: MainNavBar(
        currentIndex: _index,
        onTap: _onTabTap,
      ),
    );
  }
}
