import 'package:flutter/material.dart';
import '../providers/farmer_provider.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isFieldWorker) {
        context.read<FarmerProvider>().loadFarmers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isFarmer = authProvider.isFarmer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          if (!isFarmer)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => Navigator.pushNamed(context, '/sync-status'),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: isFarmer
            ? [
                _buildDashboardCard(
                  'My Crops',
                  Icons.grass,
                  Colors.orange,
                  () => Navigator.pushNamed(context, '/crops'),
                ),
                _buildDashboardCard(
                  'My Queries',
                  Icons.question_answer_outlined,
                  Colors.deepOrange,
                  () => Navigator.pushNamed(context, '/queries'),
                ),
                _buildDashboardCard(
                  'Weather',
                  Icons.cloud_outlined,
                  Colors.blue,
                  () => Navigator.pushNamed(context, '/weather'),
                ),
                _buildDashboardCard(
                  'Profile',
                  Icons.badge_outlined,
                  Colors.teal,
                  () => Navigator.pushNamed(context, '/profile'),
                ),
              ]
            : [
                _buildDashboardCard(
                  'Farmers',
                  Icons.people,
                  Colors.blue,
                  () => Navigator.pushNamed(context, '/farmers'),
                ),
                _buildDashboardCard(
                  'Add Farmer',
                  Icons.person_add,
                  Colors.green,
                  () => Navigator.pushNamed(context, '/farmer-registration'),
                ),
                _buildDashboardCard(
                  'Crops',
                  Icons.grass,
                  Colors.orange,
                  () => Navigator.pushNamed(context, '/crops'),
                ),
                _buildDashboardCard(
                  'Queries',
                  Icons.question_answer_outlined,
                  Colors.deepOrange,
                  () => Navigator.pushNamed(context, '/queries'),
                ),
                _buildDashboardCard(
                  'Sync Status',
                  Icons.cloud_sync,
                  Colors.purple,
                  () => Navigator.pushNamed(context, '/sync-status'),
                ),
                _buildDashboardCard(
                  'Profile',
                  Icons.badge_outlined,
                  Colors.teal,
                  () => Navigator.pushNamed(context, '/profile'),
                ),
              ],
      ),
    );
  }

  Widget _buildDashboardCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
