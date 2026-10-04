import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AppStateProvider, AuthStatus>(
      (a) => a.authStatus,
    );

    switch (status) {
      case AuthStatus.initializing:
        return const _LoadingScreen();
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return const MainShell();
      case AuthStatus.loadFailed:
        return const _LoadFailedScreen();
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('BUCKS', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _LoadFailedScreen extends StatelessWidget {
  const _LoadFailedScreen();

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppStateProvider>();
    final error = context.select<AppStateProvider, String?>((a) => a.loadError);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('BUCKS', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 16),
              Text(
                error ?? 'Could not load your data.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: app.restoreSession,
                child: const Text('Try again'),
              ),
              TextButton(
                onPressed: app.signOut,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
