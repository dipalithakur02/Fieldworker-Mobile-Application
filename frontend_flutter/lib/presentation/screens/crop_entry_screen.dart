import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../data/models/crop_model.dart';
import '../providers/crop_provider.dart';
import '../widgets/field_steward_ui.dart';

class CropEntryScreen extends StatefulWidget {
  final String farmerId;
  final CropModel? existingCrop;

  const CropEntryScreen({
    required this.farmerId,
    this.existingCrop,
    super.key,
  });

  @override
  State<CropEntryScreen> createState() => _CropEntryScreenState();
}

class _CropEntryScreenState extends State<CropEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _areaController = TextEditingController();
  final _imagePicker = ImagePicker();

  String _selectedCropType = 'Cereal';
  String _selectedSeason = 'Kharif';
  DateTime _sowingDate = DateTime.now();
  bool _isLoading = false;
  String? _selectedImagePath;
  DateTime _draftUpdatedAt = DateTime.now();

  final List<String> _cropTypes = const [
    'Cereal',
    'Pulse',
    'Vegetable',
    'Fruit',
    'Cash Crop',
  ];

  final List<String> _seasons = const ['Kharif', 'Rabi', 'Zaid'];

  bool get _isEditing => widget.existingCrop != null;

  @override
  void initState() {
    super.initState();
    final crop = widget.existingCrop;
    if (crop == null) {
      return;
    }

    _cropNameController.text = crop.cropName;
    _areaController.text = crop.area.toString();
    _selectedCropType = crop.cropType;
    _selectedSeason = crop.season;
    _sowingDate = crop.sowingDate;
    _selectedImagePath = crop.imagePath;
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _markDraftUpdated() {
    setState(() => _draftUpdatedAt = DateTime.now());
  }

  Future<void> _pickCropImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null || !mounted) {
      return;
    }

    setState(() {
      _selectedImagePath = pickedFile.path;
      _draftUpdatedAt = DateTime.now();
    });
  }

  Future<void> _pickSowingDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _sowingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      setState(() {
        _sowingDate = date;
        _draftUpdatedAt = DateTime.now();
      });
    }
  }

  Future<void> _saveCrop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final crop = CropModel(
        id: widget.existingCrop?.id,
        serverId: widget.existingCrop?.serverId,
        farmerId: widget.farmerId,
        cropName: _cropNameController.text.trim(),
        cropType: _selectedCropType,
        area: double.parse(_areaController.text),
        season: _selectedSeason,
        sowingDate: _sowingDate,
        imagePath: _selectedImagePath,
        syncStatus: widget.existingCrop?.syncStatus ?? 'PENDING',
      );

      if (_isEditing) {
        await context.read<CropProvider>().updateCrop(crop);
      } else {
        await context.read<CropProvider>().addCrop(crop);
      }

      if (!mounted) {
        return;
      }

      Helpers.showSnackBar(
        context,
        _isEditing
            ? 'Crop updated (offline sync enabled)'
            : 'Crop saved (offline sync enabled)',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }
      Helpers.showSnackBar(context, 'Failed to add crop', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatLastUpdated() {
    final difference = DateTime.now().difference(_draftUpdatedAt);
    if (difference.inMinutes < 1) {
      return 'just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    }
    return '${difference.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return FieldStewardScaffold(
      title: 'New Crop Entry',
      currentTab: FieldStewardTab.crops,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: FieldStewardColors.primaryDark,
        ),
      ),
      actions: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: FieldStewardColors.surfaceLow,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 15,
                color: FieldStewardColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'OFFLINE MODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: FieldStewardColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
      onHomeTap: () => Navigator.pushNamed(context, '/dashboard'),
      onFarmersTap: () => Navigator.pushNamed(context, '/farmers'),
      onSyncTap: () => Navigator.pushNamed(context, '/sync-status'),
      bottomOverlay: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: FieldStewardPrimaryButton(
          onPressed: _isLoading ? null : _saveCrop,
          icon: Icons.save_rounded,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isEditing ? 'Update Crop Record' : 'Save Crop Record',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          children: [
            const FieldStewardSectionHeader(
              eyebrow: 'Field Registry',
              title: 'Record the\nNew Harvest',
              description:
                  'Capture precise cultivation data for accurate yield forecasting and regional monitoring.',
            ),
            const SizedBox(height: 24),
            FieldStewardSurfaceCard(
              color: FieldStewardColors.surfaceLow,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: FieldStewardColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Draft saved locally',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: FieldStewardColors.onSurface,
                          ),
                        ),
                        Text(
                          'Last updated: ${_formatLastUpdated()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: FieldStewardColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.history_rounded,
                    color: FieldStewardColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FieldStewardTextField(
              controller: _cropNameController,
              label: 'Crop Name',
              hintText: 'e.g. Golden Highland Wheat',
              validator: (value) =>
                  Validators.validateRequired(value, 'Crop Name'),
              onChanged: (_) => _markDraftUpdated(),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final vertical = constraints.maxWidth < 430;
                final children = [
                  Expanded(
                    child: _DropdownField(
                      label: 'Crop Type',
                      value: _selectedCropType,
                      items: _cropTypes,
                      onChanged: (value) {
                        setState(() {
                          _selectedCropType = value!;
                          _draftUpdatedAt = DateTime.now();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 14, height: 14),
                  Expanded(
                    child: _DropdownField(
                      label: 'Season',
                      value: _selectedSeason,
                      items: _seasons,
                      trailingIcon: Icons.calendar_today_rounded,
                      onChanged: (value) {
                        setState(() {
                          _selectedSeason = value!;
                          _draftUpdatedAt = DateTime.now();
                        });
                      },
                    ),
                  ),
                ];

                if (vertical) {
                  return Column(children: children);
                }

                return Row(children: children);
              },
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AREA COVERAGE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: FieldStewardColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _areaController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final required =
                              Validators.validateRequired(value, 'Area');
                          if (required != null) {
                            return required;
                          }
                          return double.tryParse(value!.trim()) == null
                              ? 'Enter a valid number'
                              : null;
                        },
                        onChanged: (_) => _markDraftUpdated(),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          filled: true,
                          fillColor: FieldStewardColors.surfaceHigh,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          color: FieldStewardColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Text(
                            'Acres',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: FieldStewardColors.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: _pickSowingDate,
              child: AbsorbPointer(
                child: FieldStewardTextField(
                  label: 'Sowing Date',
                  hintText: Helpers.formatDate(_sowingDate),
                  icon: Icons.event_rounded,
                  readOnly: true,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _ImageSelector(
              imagePath: _selectedImagePath,
              onPick: _pickCropImage,
              onRemove: () {
                setState(() {
                  _selectedImagePath = null;
                  _draftUpdatedAt = DateTime.now();
                });
              },
            ),
            const SizedBox(height: 20),
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    FieldStewardColors.secondaryContainer,
                    FieldStewardColors.primaryDark.withValues(alpha: 0.78),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.14),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 22,
                    right: 22,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Region: Northern Sector',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Verification ID: #FS-992-B',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? trailingIcon;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: FieldStewardColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: FieldStewardColors.surfaceHigh,
            suffixIcon: Icon(
              trailingIcon ?? Icons.expand_more_rounded,
              color: FieldStewardColors.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ImageSelector extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImageSelector({
    required this.imagePath,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;
    final fileExists = hasImage &&
        !imagePath!.startsWith('http') &&
        File(imagePath!).existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VISUAL RECORD',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: FieldStewardColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 164,
            decoration: BoxDecoration(
              color: FieldStewardColors.surfaceLow,
              borderRadius: BorderRadius.circular(28),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (fileExists)
                    Image.file(File(imagePath!), fit: BoxFit.cover)
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            FieldStewardColors.secondaryContainer,
                            FieldStewardColors.primary.withValues(alpha: 0.22),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.image_outlined,
                              size: 34,
                              color: FieldStewardColors.primaryDark,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              hasImage
                                  ? 'Existing crop image retained'
                                  : 'Tap to attach crop image',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: FieldStewardColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    right: 14,
                    top: 14,
                    child: Row(
                      children: [
                        if (hasImage)
                          Material(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              onTap: onRemove,
                              borderRadius: BorderRadius.circular(999),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: FieldStewardColors.error,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
