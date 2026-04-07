import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/network_checker.dart';
import '../providers/farmer_provider.dart';
import '../providers/crop_provider.dart';

class SyncStatusScreen extends StatefulWidget {
  @override
  _SyncStatusScreenState createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  bool _isOnline = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final isOnline = await NetworkChecker.isConnected();
    setState(() => _isOnline = isOnline);
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      await SyncService.syncNow();
      if (!mounted) return;
      await context.read<FarmerProvider>().loadFarmers();
      await context.read<CropProvider>().loadCrops();
      Helpers.showSnackBar(context, 'Sync completed successfully');
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Sync failed', isError: true);
    } finally {
      if (!mounted) return;
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sync Status'),
        backgroundColor: Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      _isOnline ? Icons.cloud_done : Icons.cloud_off,
                      size: 80,
                      color: _isOnline ? Colors.green : Colors.red,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isOnline
                          ? 'Connected to server'
                          : 'Working in offline mode',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSyncing || !_isOnline ? null : _syncNow,
                icon: _isSyncing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(Icons.sync),
                label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Automatic sync runs every 15 minutes when online',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
