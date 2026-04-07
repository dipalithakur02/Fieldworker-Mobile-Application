import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/crop_model.dart';
import '../../data/models/farmer_model.dart';
import '../../data/repositories/crop_repository.dart';
import '../../data/repositories/farmer_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/query_provider.dart';
import '../widgets/avatar_view.dart';

class CropsScreen extends StatefulWidget {
  final String? farmerId;

  const CropsScreen({super.key, this.farmerId});

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  final CropRepository _repository = CropRepository();
  final FarmerRepository _farmerRepository = FarmerRepository();
  List<CropModel> _crops = [];
  Map<String, FarmerModel> _farmersById = {};
  bool _loading = true;
  String? _expandedCropId;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final farmers = await _farmerRepository.getAllFarmers();
      final crops = authProvider.isFarmer && widget.farmerId == null
          ? await _repository.fetchAssignedCrops()
          : widget.farmerId == null
              ? await _repository.getAllCrops()
              : await _repository.getCropsByFarmer(widget.farmerId!);

      if (!mounted) {
        return;
      }

      setState(() {
        _crops = crops;
        _farmersById = {
          for (final farmer in farmers)
            if (farmer.id != null) farmer.id!: farmer,
        };
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load crops: $error')),
      );
    }
  }

  Future<void> _deleteCrop(String id) async {
    await _repository.deleteCrop(id);
    await _loadCrops();
  }

  Future<bool> _showDeleteCropDialog(String cropName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete crop?'),
          content: Text(
            'Delete $cropName from the crop list? This action cannot be undone.',
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

  Future<void> _confirmDeleteCrop(CropModel crop) async {
    if (crop.id == null) {
      return;
    }

    final confirmed = await _showDeleteCropDialog(crop.cropName);
    if (!confirmed || !mounted) {
      return;
    }

    await _deleteCrop(crop.id!);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${crop.cropName} deleted')),
    );
  }

  Future<void> _editCrop(CropModel crop) async {
    await Navigator.pushNamed(
      context,
      '/crop-entry',
      arguments: {
        'farmerId': crop.farmerId,
        'crop': crop,
      },
    );

    if (!mounted) {
      return;
    }

    await _loadCrops();
  }

  Future<void> _raiseQuery(CropModel crop) async {
    await Navigator.pushNamed(
      context,
      '/query-create',
      arguments: crop,
    );

    if (!mounted) {
      return;
    }

    await context.read<QueryProvider>().loadQueries();
  }

  FarmerModel? _localFarmerForCrop(CropModel crop) {
    final farmer = _farmersById[crop.farmerId];
    if (farmer != null) {
      return farmer;
    }

    if (widget.farmerId != null) {
      return _farmersById[widget.farmerId!];
    }

    return null;
  }

  String _farmerName(CropModel crop, AuthProvider authProvider) {
    if (authProvider.isFarmer) {
      return crop.farmerName ?? authProvider.user?.name ?? 'Farmer';
    }

    return _localFarmerForCrop(crop)?.name ?? crop.farmerName ?? 'Farmer';
  }

  String? _farmerVillage(CropModel crop, AuthProvider authProvider) {
    if (authProvider.isFarmer) {
      return crop.farmerVillage;
    }

    return _localFarmerForCrop(crop)?.village ?? crop.farmerVillage;
  }

  String? _farmerMobile(CropModel crop, AuthProvider authProvider) {
    if (authProvider.isFarmer) {
      return crop.farmerMobile ?? authProvider.user?.phone;
    }

    return _localFarmerForCrop(crop)?.mobile ?? crop.farmerMobile;
  }

  String? _farmerImagePath(CropModel crop, AuthProvider authProvider) {
    if (authProvider.isFarmer) {
      return authProvider.user?.profileImagePath;
    }

    return _localFarmerForCrop(crop)?.profileImagePath;
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(AppConstants.primaryColor)),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildCropImage(CropModel crop) {
    final imagePath = crop.imagePath?.trim();

    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: const Center(
          child: Text('No crop image available'),
        ),
      );
    }

    if (imagePath.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          imagePath,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text('Unable to load crop image'),
          ),
        ),
      );
    }

    final imageFile = File(imagePath);
    if (imageFile.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.file(
          imageFile,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: const Center(
        child: Text('Crop image is attached on another device'),
      ),
    );
  }

  Widget _buildCropActions(CropModel crop, bool isFarmer) {
    if (isFarmer) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: () => _raiseQuery(crop),
          icon: const Icon(Icons.healing_outlined),
          label: const Text('Raise Disease Query'),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(
          onPressed: () => _editCrop(crop),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Crop'),
        ),
        OutlinedButton.icon(
          onPressed: () => _confirmDeleteCrop(crop),
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text('Delete Crop'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        ),
      ],
    );
  }

  Widget _buildCropCard(
    CropModel crop,
    bool isFarmer,
    AuthProvider authProvider,
  ) {
    final isExpanded = _expandedCropId == crop.id;
    final farmerName = _farmerName(crop, authProvider);
    final farmerVillage = _farmerVillage(crop, authProvider);
    final farmerMobile = _farmerMobile(crop, authProvider);
    final farmerImagePath = _farmerImagePath(crop, authProvider);

    return Card(
      elevation: isExpanded ? 8 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFFFFCF4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          setState(() {
            _expandedCropId = isExpanded ? null : crop.id;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: isExpanded
                  ? const [
                      Color(0xFFF8F3DF),
                      Color(0xFFE7F2DB),
                    ]
                  : const [
                      Color(0xFFFFFCF4),
                      Color(0xFFF3F8EA),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: const Color(AppConstants.primaryColor)
                          .withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.grass,
                      color: Color(AppConstants.primaryColor),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.cropName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${crop.cropType} • ${crop.area} acres • ${crop.season}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: const Color(AppConstants.primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildDetailChip(Icons.event, _formatDate(crop.sowingDate)),
                  _buildDetailChip(Icons.sync, crop.syncStatus),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    children: [
                      AvatarView(
                        imagePath: farmerImagePath,
                        fallbackLabel: farmerName,
                        radius: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              farmerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            if ((farmerVillage ?? '').isNotEmpty)
                              Text(
                                farmerVillage!,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            if ((farmerMobile ?? '').isNotEmpty)
                              Text(
                                farmerMobile!,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCropImage(crop),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildDetailChip(Icons.eco_outlined, crop.cropName),
                    _buildDetailChip(Icons.category_outlined, crop.cropType),
                    _buildDetailChip(Icons.landscape_outlined, crop.season),
                    _buildDetailChip(Icons.straighten, '${crop.area} acres'),
                  ],
                ),
                const SizedBox(height: 18),
                _buildCropActions(crop, isFarmer),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isFarmer = authProvider.isFarmer;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2E8),
      appBar: AppBar(
        title: Text(
          isFarmer && widget.farmerId == null
              ? 'My Crops'
              : widget.farmerId == null
                  ? 'Crops'
                  : 'Farmer Crops',
        ),
        backgroundColor: const Color(AppConstants.primaryColor),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8F5E9),
              Color(0xFFEAF3DE),
              Color(0xFFF4EEE1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _crops.isEmpty
                ? Center(
                    child: Text(
                      isFarmer
                          ? 'No crops assigned to your account yet'
                          : 'No crops found',
                      style: const TextStyle(fontSize: 18),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCrops,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _crops.length,
                      itemBuilder: (context, index) {
                        return _buildCropCard(
                          _crops[index],
                          isFarmer,
                          authProvider,
                        );
                      },
                    ),
                  ),
      ),
      floatingActionButton: isFarmer
          ? null
          : FloatingActionButton(
              backgroundColor: const Color(AppConstants.primaryColor),
              child: const Icon(Icons.add),
              onPressed: () async {
                if (widget.farmerId == null) {
                  Navigator.pushNamed(context, '/farmers');
                  return;
                }

                await Navigator.pushNamed(
                  context,
                  '/crop-entry',
                  arguments: widget.farmerId,
                );

                if (!mounted) {
                  return;
                }

                await _loadCrops();
              },
            ),
    );
  }
}
