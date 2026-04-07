import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'mpin_lock_screen.dart';

class SessionGateScreen extends StatefulWidget {
  const SessionGateScreen({super.key});

  @override
  State<SessionGateScreen> createState() => _SessionGateScreenState();
}

class _SessionGateScreenState extends State<SessionGateScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().initializeSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _handleLifecycleChange(state);
  }

  Future<void> _handleLifecycleChange(AppLifecycleState state) async {
    if (!mounted) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    await authProvider.handleAppLifecycleState(state);

    if (!mounted || !authProvider.isLocked) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isInitializing) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!authProvider.isSignedIn) {
          return const LoginScreen();
        }

        if (authProvider.isLocked) {
          return const MpinLockScreen();
        }

        return const DashboardScreen();
      },
    );
  }
}
