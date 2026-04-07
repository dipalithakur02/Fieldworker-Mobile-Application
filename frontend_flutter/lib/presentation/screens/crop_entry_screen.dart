import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/crop_model.dart';
import '../../presentation/providers/crop_provider.dart';
import '../../core/constants/app_constants.dart';

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

  final TextEditingController _cropNameController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  String _selectedCropType = 'Cereal';
  String _selectedSeason = 'Kharif';
  DateTime _sowingDate = DateTime.now();

  bool _isLoading = false;
  String? _selectedImagePath;
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _cropTypes = [
    'Cereal',
    'Pulse',
    'Vegetable',
    'Fruit',
    'Cash Crop'
  ];

  final List<String> _seasons = ['Kharif', 'Rabi', 'Zaid'];

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

  Future<void> _pickCropImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() => _selectedImagePath = pickedFile.path);
  }

  Future<void> _saveCrop() async {
    if (!_formKey.currentState!.validate()) return;

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

      if (!mounted) return;

      Helpers.showSnackBar(
        context,
        _isEditing
            ? "Crop updated (offline sync enabled)"
            : "Crop saved (offline sync enabled)",
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, "Failed to add crop", isError: true);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(AppConstants.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    final imagePath = _selectedImagePath;
    final localImageExists = imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    return GestureDetector(
      onTap: _pickCropImage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: imagePath == null
            ? const Row(
                children: [
                  Icon(Icons.image_outlined),
                  SizedBox(width: 10),
                  Text('Tap to select crop image'),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (localImageExists)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imagePath),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Existing crop image is attached'),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(localImageExists
                          ? 'Image selected'
                          : 'Image retained'),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _selectedImagePath = null);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        AppConstants.secondaryColor,
      ).withValues(alpha: 0.1),
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Crop" : "Add Crop"),
        backgroundColor: const Color(AppConstants.primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Icon(Icons.grass,
                      size: 80, color: Color(AppConstants.primaryColor)),
                  const SizedBox(height: 25),
                  _buildSectionTitle("Crop Name"),
                  TextFormField(
                    controller: _cropNameController,
                    decoration: InputDecoration(
                      hintText: "Enter crop name",
                      prefixIcon: const Icon(Icons.agriculture),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) =>
                        Validators.validateRequired(v, "Crop Name"),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Crop Type"),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCropType,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _cropTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCropType = v!),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Area (Acres)"),
                  TextFormField(
                    controller: _areaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.square_foot),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => Validators.validateRequired(v, "Area"),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Crop Image (Optional)"),
                  _buildImageSelector(),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Season"),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSeason,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.wb_sunny),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _seasons
                        .map((season) => DropdownMenuItem(
                              value: season,
                              child: Text(season),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSeason = v!),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Sowing Date"),
                  ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.grey)),
                    leading: const Icon(Icons.calendar_today),
                    title: Text(Helpers.formatDate(_sowingDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _sowingDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );

                      if (date != null) {
                        setState(() => _sowingDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isEditing ? "Update Crop" : "Save Crop"),
                      onPressed: _isLoading ? null : _saveCrop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppConstants.primaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
