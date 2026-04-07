import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/helpers.dart';
import '../providers/auth_provider.dart';

class MpinLockScreen extends StatefulWidget {
  const MpinLockScreen({super.key});

  @override
  State<MpinLockScreen> createState() => _MpinLockScreenState();
}

class _MpinLockScreenState extends State<MpinLockScreen> {
  final _mpinController = TextEditingController();
  bool _isUnlocking = false;

  @override
  void dispose() {
    _mpinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final mpin = _mpinController.text.trim();
    if (mpin.length != 4) {
      Helpers.showSnackBar(context, 'Enter your 4-digit MPIN', isError: true);
      return;
    }

    setState(() => _isUnlocking = true);

    final unlocked = await context.read<AuthProvider>().unlockWithMpin(mpin);

    if (!mounted) {
      return;
    }

    setState(() => _isUnlocking = false);

    if (!unlocked) {
      Helpers.showSnackBar(context, 'Incorrect MPIN', isError: true);
      return;
    }

    _mpinController.clear();
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: Color(0xFF2E7D32),
                        child: Icon(Icons.lock_outline,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enter MPIN',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user?.name.isNotEmpty == true
                            ? 'Welcome back, ${user!.name}'
                            : 'Unlock the app to continue',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _mpinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        decoration: const InputDecoration(
                          labelText: '4-digit MPIN',
                          prefixIcon: Icon(Icons.pin),
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isUnlocking ? null : _unlock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: _isUnlocking
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Unlock'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isUnlocking ? null : _logout,
                        child: const Text('Logout and sign in again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
