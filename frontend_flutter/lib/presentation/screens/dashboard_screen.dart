import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/network_checker.dart';
import '../providers/auth_provider.dart';
import '../providers/farmer_provider.dart';
import '../widgets/field_steward_ui.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isFieldWorker) {
        await context.read<FarmerProvider>().loadFarmers();
      }
      await _loadNetworkStatus();
    });
  }

  Future<void> _loadNetworkStatus() async {
    final isOnline = await NetworkChecker.isConnected();
    if (mounted) {
      setState(() => _isOnline = isOnline);
    }
  }

  void _navigate(String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final farmerProvider = context.watch<FarmerProvider>();
    final isFarmer = authProvider.isFarmer;
    final rawUserName = authProvider.user?.name.trim();
    final userName = rawUserName != null && rawUserName.isNotEmpty
        ? authProvider.user!.name
        : 'Steward One';

    final actions = isFarmer
        ? [
            _DashboardAction(
              title: 'My Crops',
              icon: Icons.eco_rounded,
              color: FieldStewardColors.tertiaryFixed,
              iconColor: const Color(0xFF7F2448),
              onTap: () => _navigate('/crops'),
            ),
            _DashboardAction(
              title: 'My Queries',
              icon: Icons.forum_outlined,
              color: FieldStewardColors.surfaceHighest,
              iconColor: FieldStewardColors.onSurfaceVariant,
              onTap: () => _navigate('/queries'),
            ),
            _DashboardAction(
              title: 'Weather',
              icon: Icons.wb_sunny_rounded,
              color: FieldStewardColors.primaryFixed,
              iconColor: const Color(0xFF005312),
              onTap: () => _navigate('/weather'),
            ),
            _DashboardAction(
              title: 'Profile',
              icon: Icons.badge_outlined,
              color: FieldStewardColors.secondaryContainer,
              iconColor: const Color(0xFF304E2E),
              onTap: () => _navigate('/profile'),
            ),
          ]
        : [
            _DashboardAction(
              title: 'Register\nFarmer',
              icon: Icons.person_add_alt_1_rounded,
              color: FieldStewardColors.secondaryContainer,
              iconColor: const Color(0xFF304E2E),
              onTap: () => _navigate('/farmer-registration'),
            ),
            _DashboardAction(
              title: 'View\nFarmers',
              icon: Icons.group_rounded,
              color: FieldStewardColors.primaryFixed,
              iconColor: const Color(0xFF002204),
              onTap: () => _navigate('/farmers'),
            ),
            _DashboardAction(
              title: 'Add\nCrop',
              icon: Icons.agriculture_rounded,
              color: FieldStewardColors.tertiaryFixed,
              iconColor: const Color(0xFF7F2448),
              onTap: () => _navigate('/farmers'),
            ),
            _DashboardAction(
              title: 'Sync\nData',
              icon: Icons.sync_rounded,
              color: FieldStewardColors.surfaceHighest,
              iconColor: FieldStewardColors.onSurfaceVariant,
              onTap: () => _navigate('/sync-status'),
            ),
          ];

    return FieldStewardScaffold(
      title: 'FieldSteward',
      currentTab: FieldStewardTab.home,
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: FieldStewardColors.surfaceHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(
                _isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                color: FieldStewardColors.onSurfaceVariant,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _isOnline ? 'Online' : 'Offline',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: FieldStewardColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            _loadNetworkStatus();
            if (!isFarmer) {
              _navigate('/sync-status');
            }
          },
          icon: const Icon(
            Icons.sync_rounded,
            color: FieldStewardColors.primaryDark,
          ),
        ),
      ],
      onFarmersTap: () => _navigate('/farmers'),
      onCropsTap: () => _navigate('/crops'),
      onSyncTap: () => _navigate('/sync-status'),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!isFarmer) {
            await farmerProvider.loadFarmers();
          }
          await _loadNetworkStatus();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          children: [
            Text(
              'Welcome,',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: FieldStewardColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              userName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 42,
                    height: 1,
                    color: FieldStewardColors.primaryDark,
                  ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FieldStewardColors.primary,
                    FieldStewardColors.primaryDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        FieldStewardColors.primaryDark.withValues(alpha: 0.24),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Northern Sector',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '28°C',
                              style: TextStyle(
                                fontSize: 48,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isFarmer
                                  ? 'Clear skies • Good for monitoring'
                                  : 'Partly Cloudy • Humidity 64%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(
                            Icons.wb_sunny_rounded,
                            size: 58,
                            color: FieldStewardColors.primaryFixed,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'OPTIMAL GRAZING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 620 ? 4 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: actions.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final action = actions[index];
                    return _DashboardTile(action: action);
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            FieldStewardSurfaceCard(
              color: FieldStewardColors.surfaceLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Harvest Health',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: FieldStewardColors.onSurface,
                          ),
                        ),
                      ),
                      FieldStewardStatusBadge(
                        label: isFarmer ? 'Stable' : 'Alert',
                        backgroundColor: isFarmer
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFE5EC),
                        foregroundColor: isFarmer
                            ? FieldStewardColors.success
                            : FieldStewardColors.tertiaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: FieldStewardColors.primary,
                            width: 5,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '82%',
                            style: TextStyle(
                              color: FieldStewardColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          isFarmer
                              ? 'Your crop reports are up to date and ready for query support.'
                              : '${farmerProvider.farmers.length} active farmers tracked. Northern sector shows strong yield momentum this cycle.',
                          style: const TextStyle(
                            height: 1.5,
                            color: FieldStewardColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardAction {
  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _DashboardAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });
}

class _DashboardTile extends StatelessWidget {
  final _DashboardAction action;

  const _DashboardTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: action.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(action.icon, color: action.iconColor, size: 28),
              ),
              const Spacer(),
              Text(
                action.title,
                style: const TextStyle(
                  fontSize: 21,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: FieldStewardColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
