import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../data/models/farmer_model.dart';
import '../providers/farmer_provider.dart';
import '../widgets/avatar_view.dart';
import '../widgets/field_steward_ui.dart';

class FarmerRegistrationScreen extends StatefulWidget {
  final FarmerModel? existingFarmer;

  const FarmerRegistrationScreen({super.key, this.existingFarmer});

  @override
  State<FarmerRegistrationScreen> createState() =>
      _FarmerRegistrationScreenState();
}

class _FarmerRegistrationScreenState extends State<FarmerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _accountPasswordController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _createLoginAccount = false;
  Position? _currentPosition;
  String? _profileImagePath;

  bool get _isEditing => widget.existingFarmer != null;
  bool get _hasExistingAccount =>
      widget.existingFarmer?.userId != null &&
      widget.existingFarmer!.userId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final farmer = widget.existingFarmer;
    if (farmer == null) {
      return;
    }

    _nameController.text = farmer.name;
    _villageController.text = farmer.village;
    _mobileController.text = farmer.mobile;
    _addressController.text = farmer.address ?? '';
    _profileImagePath = farmer.profileImagePath;
    _createLoginAccount = _hasExistingAccount;

    if (farmer.latitude != null && farmer.longitude != null) {
      _currentPosition = Position(
        longitude: farmer.longitude!,
        latitude: farmer.latitude!,
        timestamp: farmer.createdAt ?? DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _accountPasswordController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    final locationDetails = await LocationService.getCurrentLocationDetails();

    if (!mounted) {
      return;
    }

    final status = locationDetails?.status ?? LocationFetchStatus.unavailable;
    if (status == LocationFetchStatus.success && locationDetails != null) {
      setState(() {
        _currentPosition = locationDetails.position;
        if ((locationDetails.village ?? '').isNotEmpty &&
            _villageController.text.trim().isEmpty) {
          _villageController.text = locationDetails.village!;
        }
        if ((locationDetails.address ?? '').isNotEmpty) {
          _addressController.text = locationDetails.address!;
        }
        _isLoading = false;
      });

      Helpers.showSnackBar(
        context,
        (locationDetails.address ?? '').isNotEmpty
            ? 'Location, village, and address captured successfully'
            : 'Location captured, but address could not be resolved',
      );
      return;
    }

    setState(() => _isLoading = false);

    final message = switch (status) {
      LocationFetchStatus.serviceDisabled =>
        'Turn on device location services and try again',
      LocationFetchStatus.permissionDenied =>
        'Location permission is required to capture village and address',
      LocationFetchStatus.permissionDeniedForever =>
        'Location permission is permanently denied. Enable it from app settings',
      _ => 'Unable to fetch the current location right now',
    };

    Helpers.showSnackBar(context, message, isError: true);
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null || !mounted) {
      return;
    }

    setState(() => _profileImagePath = pickedFile.path);
  }

  Future<void> _saveFarmer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final farmer = FarmerModel(
        id: widget.existingFarmer?.id,
        serverId: widget.existingFarmer?.serverId,
        userId: widget.existingFarmer?.userId,
        profileImagePath: _profileImagePath,
        name: _nameController.text.trim(),
        village: _villageController.text.trim(),
        mobile: _mobileController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        syncStatus: widget.existingFarmer?.syncStatus ?? 'PENDING',
        createdAt: widget.existingFarmer?.createdAt,
      );

      if (_isEditing) {
        await context.read<FarmerProvider>().updateFarmer(
              farmer,
              createLoginAccount: !_hasExistingAccount && _createLoginAccount,
              accountPassword: _accountPasswordController.text.trim().isEmpty
                  ? null
                  : _accountPasswordController.text.trim(),
            );
      } else {
        await context.read<FarmerProvider>().addFarmer(
              farmer,
              createLoginAccount: _createLoginAccount,
              accountPassword: _accountPasswordController.text.trim().isEmpty
                  ? null
                  : _accountPasswordController.text.trim(),
            );
      }

      if (!mounted) {
        return;
      }

      Helpers.showSnackBar(
        context,
        _isEditing
            ? 'Farmer updated successfully'
            : 'Farmer registered successfully',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }
      Helpers.showSnackBar(context, 'Failed to save farmer: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FieldStewardScaffold(
      title: 'FieldSteward',
      currentTab: FieldStewardTab.farmers,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: FieldStewardColors.primaryDark,
        ),
      ),
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
      bottomOverlay: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: FieldStewardPrimaryButton(
          onPressed: _isLoading ? null : _saveFarmer,
          icon: Icons.save_rounded,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _isEditing ? 'Update Farmer' : 'Save Farmer',
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
            FieldStewardSectionHeader(
              eyebrow: 'Registration Portal',
              title: _isEditing
                  ? 'Update Farmer\nRegistry'
                  : 'New Farmer\nRegistry',
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _pickProfileImage,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        AvatarView(
                          imagePath: _profileImagePath,
                          fallbackLabel: _nameController.text.isEmpty
                              ? 'Farmer'
                              : _nameController.text,
                          radius: 48,
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: FieldStewardColors.primaryDark,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _profileImagePath == null
                          ? 'Tap to add farmer profile picture'
                          : 'Tap to change farmer profile picture',
                      style: const TextStyle(
                        color: FieldStewardColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((_profileImagePath ?? '').isNotEmpty)
                      TextButton(
                        onPressed: () =>
                            setState(() => _profileImagePath = null),
                        child: const Text('Remove picture'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            FieldStewardTextField(
              controller: _nameController,
              label: 'Full Legal Name',
              hintText: 'e.g. Samuel Adewale',
              validator: (value) => Validators.validateRequired(value, 'Name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            FieldStewardTextField(
              controller: _villageController,
              label: 'Home Village',
              hintText: 'Select or type village',
              icon: Icons.location_city_rounded,
              validator: (value) =>
                  Validators.validateRequired(value, 'Village'),
            ),
            const SizedBox(height: 18),
            FieldStewardTextField(
              controller: _mobileController,
              label: 'Mobile Number',
              hintText: '+91 98765 43210',
              keyboardType: TextInputType.phone,
              validator: Validators.validatePhone,
            ),
            const SizedBox(height: 18),
            FieldStewardTextField(
              controller: _addressController,
              label: 'Primary Address',
              hintText: 'Street details or landmarks...',
              maxLines: 3,
              helperText:
                  'Location permission auto-fills the address when available',
            ),
            const SizedBox(height: 24),
            FieldStewardSurfaceCard(
              color: FieldStewardColors.surfaceLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location Data',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: FieldStewardColors.onSurface,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Precision GPS coordinates required for record validation.',
                              style: TextStyle(
                                color: FieldStewardColors.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.my_location_rounded,
                        color: FieldStewardColors.primary,
                        size: 30,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          FieldStewardColors.secondaryContainer,
                          FieldStewardColors.primary.withValues(alpha: 0.38),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: FieldStewardColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                  if (_currentPosition != null) ...[
                    const SizedBox(height: 14),
                    FieldStewardIconChip(
                      icon: Icons.pin_drop_rounded,
                      label:
                          '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      backgroundColor: Colors.white,
                      foregroundColor: FieldStewardColors.primaryDark,
                    ),
                    if (_villageController.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      FieldStewardIconChip(
                        icon: Icons.location_city_rounded,
                        label: _villageController.text.trim(),
                        backgroundColor: Colors.white,
                        foregroundColor: FieldStewardColors.primaryDark,
                      ),
                    ],
                  ],
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _getLocation,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      side: BorderSide.none,
                      backgroundColor: Colors.white,
                      foregroundColor: FieldStewardColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.map_outlined),
                    label: const Text(
                      'Capture GPS Location',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FieldStewardSurfaceCard(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _hasExistingAccount ? true : _createLoginAccount,
                    onChanged: _hasExistingAccount
                        ? null
                        : (value) =>
                            setState(() => _createLoginAccount = value),
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: FieldStewardColors.primaryDark,
                    title: const Text(
                      'Enable farmer login',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: FieldStewardColors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      _hasExistingAccount
                          ? 'Farmer can already sign in using mobile number and password'
                          : 'Create login credentials for the farmer',
                    ),
                  ),
                  if (!_hasExistingAccount && _createLoginAccount) ...[
                    const SizedBox(height: 10),
                    FieldStewardTextField(
                      controller: _accountPasswordController,
                      label: 'Initial Password',
                      hintText: 'Enter initial password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                      validator: (value) {
                        if (!_createLoginAccount) {
                          return null;
                        }
                        return Validators.validatePassword(value);
                      },
                      helperText:
                          'Farmer will sign in using the mobile number above',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
