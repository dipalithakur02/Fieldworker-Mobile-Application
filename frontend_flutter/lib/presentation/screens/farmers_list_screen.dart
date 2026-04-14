import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/farmer_model.dart';
import '../providers/farmer_provider.dart';
import '../widgets/farmer_card.dart';
import '../widgets/field_steward_ui.dart';

class FarmersListScreen extends StatefulWidget {
  const FarmersListScreen({super.key});

  @override
  State<FarmersListScreen> createState() => _FarmersListScreenState();
}

class _FarmersListScreenState extends State<FarmersListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerProvider>().loadFarmers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _showDeleteFarmerDialog(String farmerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete farmer?'),
          content: Text(
            'Delete $farmerName and all crops linked to this farmer? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _deleteFarmer(
    FarmerProvider provider,
    String farmerId,
    String farmerName,
  ) async {
    final confirmed = await _showDeleteFarmerDialog(farmerName);
    if (!confirmed || !mounted) {
      return;
    }

    await provider.deleteFarmer(farmerId);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$farmerName and related crops deleted')),
    );
  }

  Future<void> _editFarmer(FarmerModel farmer) async {
    await Navigator.pushNamed(
      context,
      '/farmer-registration',
      arguments: farmer,
    );

    if (mounted) {
      await context.read<FarmerProvider>().loadFarmers();
    }
  }

  List<FarmerModel> _filterFarmers(List<FarmerModel> farmers) {
    if (_searchQuery.isEmpty) {
      return farmers;
    }

    return farmers.where((farmer) {
      return farmer.name.toLowerCase().contains(_searchQuery) ||
          farmer.village.toLowerCase().contains(_searchQuery) ||
          farmer.mobile.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FieldStewardScaffold(
      title: 'Farmers',
      currentTab: FieldStewardTab.farmers,
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/sync-status'),
          icon: const Icon(
            Icons.sync_rounded,
            color: FieldStewardColors.primaryDark,
          ),
        ),
      ],
      onHomeTap: () => Navigator.pushNamed(context, '/dashboard'),
      onCropsTap: () => Navigator.pushNamed(context, '/crops'),
      onSyncTap: () => Navigator.pushNamed(context, '/sync-status'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/farmer-registration'),
        elevation: 8,
        backgroundColor: FieldStewardColors.primaryDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Consumer<FarmerProvider>(
        builder: (context, provider, child) {
          final filteredFarmers = _filterFarmers(provider.farmers);

          return RefreshIndicator(
            onRefresh: provider.loadFarmers,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
              children: [
                FieldStewardTextField(
                  controller: _searchController,
                  label: 'Search',
                  hintText: 'Search by name, village, or mobile',
                  icon: Icons.search_rounded,
                  suffix: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                ),
                const SizedBox(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Farmer Registry',
                            style: TextStyle(
                              fontSize: 30,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: FieldStewardColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${provider.farmers.length} active farmers in registry',
                            style: const TextStyle(
                              color: FieldStewardColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: FieldStewardColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF304E2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filteredFarmers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: FieldStewardSurfaceCard(
                      color: FieldStewardColors.surfaceLow,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 72,
                            color: FieldStewardColors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No farmers registered yet'
                                : 'No farmers found for your search',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: FieldStewardColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredFarmers.map(
                    (farmer) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FarmerCard(
                        farmer: farmer,
                        onEdit: farmer.id == null
                            ? null
                            : () => _editFarmer(farmer),
                        onDelete: farmer.id == null
                            ? null
                            : () => _deleteFarmer(
                                  provider,
                                  farmer.id!,
                                  farmer.name,
                                ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
