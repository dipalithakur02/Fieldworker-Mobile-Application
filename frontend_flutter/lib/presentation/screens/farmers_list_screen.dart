import 'package:flutter/material.dart';
import '../../data/models/farmer_model.dart';
import '../providers/farmer_provider.dart';
import '../widgets/farmer_card.dart';
import 'package:provider/provider.dart';

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
      SnackBar(
        content: Text('$farmerName and related crops deleted'),
      ),
    );
  }

  Future<void> _editFarmer(FarmerModel farmer) async {
    await Navigator.pushNamed(
      context,
      '/farmer-registration',
      arguments: farmer,
    );

    if (!mounted) {
      return;
    }

    await context.read<FarmerProvider>().loadFarmers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farmers List'),
        backgroundColor: Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: Icon(Icons.wb_sunny),
            onPressed: () => Navigator.pushNamed(context, '/weather'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, village, or mobile',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: Consumer<FarmerProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }

                final filteredFarmers = provider.farmers.where((farmer) {
                  if (_searchQuery.isEmpty) return true;
                  return farmer.name.toLowerCase().contains(_searchQuery) ||
                      farmer.village.toLowerCase().contains(_searchQuery) ||
                      farmer.mobile.contains(_searchQuery);
                }).toList();

                if (filteredFarmers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No farmers registered yet'
                              : 'No farmers found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadFarmers(),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredFarmers.length,
                    itemBuilder: (context, index) {
                      final farmer = filteredFarmers[index];
                      return FarmerCard(
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
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/farmer-registration'),
        backgroundColor: Color(0xFF2E7D32),
        child: Icon(Icons.add),
      ),
    );
  }
}
