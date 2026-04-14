import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/network_checker.dart';
import '../providers/crop_provider.dart';
import '../providers/farmer_provider.dart';
import '../widgets/field_steward_ui.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  bool _isOnline = false;
  bool _isSyncing = false;
  DateTime? _lastSyncAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refresh();
    });
  }

  Future<void> _refresh() async {
    final farmerProvider = context.read<FarmerProvider>();
    final cropProvider = context.read<CropProvider>();
    final isOnline = await NetworkChecker.isConnected();
    if (!mounted) {
      return;
    }

    setState(() => _isOnline = isOnline);
    await farmerProvider.loadFarmers();
    await cropProvider.loadCrops();
  }

  Future<void> _syncNow() async {
    final farmerProvider = context.read<FarmerProvider>();
    final cropProvider = context.read<CropProvider>();
    setState(() => _isSyncing = true);

    try {
      await SyncService.syncNow();
      if (!mounted) {
        return;
      }
      setState(() => _lastSyncAt = DateTime.now());
      await farmerProvider.loadFarmers();
      await cropProvider.loadCrops();
      if (!mounted) {
        return;
      }
      Helpers.showSnackBar(context, 'Sync completed successfully');
    } catch (e) {
      if (!mounted) {
        return;
      }
      Helpers.showSnackBar(context, 'Sync failed', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) {
      return 'Today, --:--';
    }

    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return 'Today, ${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final farmerProvider = context.watch<FarmerProvider>();
    final cropProvider = context.watch<CropProvider>();

    final farmers = farmerProvider.farmers;
    final crops = cropProvider.crops;
    final pendingFarmers = farmers
        .where((item) => item.syncStatus.toUpperCase() != 'SYNCED')
        .length;
    final pendingCrops =
        crops.where((item) => item.syncStatus.toUpperCase() != 'SYNCED').length;
    final syncedFarmers = farmers
        .where((item) => item.syncStatus.toUpperCase() == 'SYNCED')
        .length;
    final syncedCrops =
        crops.where((item) => item.syncStatus.toUpperCase() == 'SYNCED').length;
    final pendingRecords = pendingFarmers + pendingCrops;
    final syncedRecords = syncedFarmers + syncedCrops;
    final totalRecords = pendingRecords + syncedRecords;
    final progress = totalRecords == 0 ? 0.0 : syncedRecords / totalRecords;

    final historyItems = [
      _SyncHistoryItem(
        title: 'Crop Records Queue',
        subtitle:
            '$pendingCrops pending • ${_isOnline ? 'Ready to upload' : 'Offline'}',
        icon: Icons.pending_actions_rounded,
        isError: false,
        trailing: _isSyncing ? 'now' : '2m ago',
      ),
      _SyncHistoryItem(
        title: 'Farmer Registry Update',
        subtitle: '$syncedFarmers records • Successful',
        icon: Icons.check_circle_rounded,
        isError: false,
        trailing: _lastSyncAt == null ? 'Today' : 'just now',
      ),
      _SyncHistoryItem(
        title: _isOnline ? 'Connection Stable' : 'Network Unavailable',
        subtitle: _isOnline
            ? 'Sync can continue in background'
            : 'Reconnect to transfer queued data',
        icon: _isOnline ? Icons.cloud_done_rounded : Icons.error_rounded,
        isError: !_isOnline,
        trailing: _isOnline ? 'Live' : 'Pending',
      ),
    ];

    return FieldStewardScaffold(
      title: 'Sync Manager',
      currentTab: FieldStewardTab.sync,
      actions: [
        IconButton(
          onPressed: _refresh,
          icon: const Icon(
            Icons.sync_rounded,
            color: FieldStewardColors.primaryDark,
          ),
        ),
      ],
      onHomeTap: () => Navigator.pushNamed(context, '/dashboard'),
      onFarmersTap: () => Navigator.pushNamed(context, '/farmers'),
      onCropsTap: () => Navigator.pushNamed(context, '/crops'),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FieldStewardColors.primaryDark,
                    FieldStewardColors.primary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        FieldStewardColors.primaryDark.withValues(alpha: 0.22),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 8,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                        Transform.rotate(
                          angle: -math.pi / 2,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 8,
                            color: FieldStewardColors.primaryFixed,
                          ),
                        ),
                        Center(
                          child: Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Overall Progress',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSyncing ? 'Syncing Records...' : 'Records Ready to Sync',
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Last Sync: ${_formatTimestamp(_lastSyncAt)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '$pendingRecords',
                    label: 'Pending Records',
                    icon: Icons.pending_actions_rounded,
                    color: FieldStewardColors.tertiaryContainer,
                    background: const Color(0xFFFCE8EE),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    value: '$syncedRecords',
                    label: 'Synced Records',
                    icon: Icons.cloud_done_rounded,
                    color: FieldStewardColors.primaryDark,
                    background: const Color(0xFFE8F5E9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            FieldStewardPrimaryButton(
              onPressed: _isSyncing || !_isOnline ? null : _syncNow,
              icon: Icons.sync_rounded,
              child: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Sync Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            Text(
              _isOnline
                  ? 'Using local storage. Keep the network stable for optimal data transfer.'
                  : 'Offline mode active. Records remain queued locally until the device reconnects.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FieldStewardColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sync History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: FieldStewardColors.onSurface,
                    ),
                  ),
                ),
                Text(
                  'View All',
                  style: TextStyle(
                    color: FieldStewardColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...historyItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryTile(item: item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return FieldStewardSurfaceCard(
      color: FieldStewardColors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: FieldStewardColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: FieldStewardColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncHistoryItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isError;
  final String trailing;

  const _SyncHistoryItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isError,
    required this.trailing,
  });
}

class _HistoryTile extends StatelessWidget {
  final _SyncHistoryItem item;

  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return FieldStewardSurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.isError
                  ? const Color(0xFFFFE0E0)
                  : FieldStewardColors.surfaceLow,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              item.icon,
              color: item.isError
                  ? FieldStewardColors.error
                  : FieldStewardColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: FieldStewardColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: FieldStewardColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.trailing,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: FieldStewardColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
