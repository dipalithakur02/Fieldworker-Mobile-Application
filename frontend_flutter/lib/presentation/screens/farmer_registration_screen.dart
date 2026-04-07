import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/location_service.dart';
import '../../data/models/farmer_model.dart';
import '../providers/farmer_provider.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/avatar_view.dart';

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
  Position? _currentPosition;
  bool _createLoginAccount = false;
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

    _createLoginAccount = _hasExistingAccount;
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

    if (!mounted) return;

    setState(() {
      _currentPosition = locationDetails?.position;
      if ((locationDetails?.address ?? '').isNotEmpty) {
        _addressController.text = locationDetails!.address!;
      }
      _isLoading = false;
    });

    if (_currentPosition != null) {
      final hasAddress = (locationDetails?.address ?? '').isNotEmpty;
      Helpers.showSnackBar(
        context,
        hasAddress
            ? 'Location and address captured successfully'
            : 'Location captured, but address could not be resolved',
      );
    } else {
      Helpers.showSnackBar(
        context,
        'Location permission is required to fetch the address',
        isError: true,
      );
    }
  }

  Future<void> _saveFarmer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final farmer = FarmerModel(
        id: widget.existingFarmer?.id,
        serverId: widget.existingFarmer?.serverId,
        userId: widget.existingFarmer?.userId,
        profileImagePath: _profileImagePath,
        name: _nameController.text,
        village: _villageController.text,
        mobile: _mobileController.text,
        address: _addressController.text,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        syncStatus: widget.existingFarmer?.syncStatus ?? 'PENDING',
        createdAt: widget.existingFarmer?.createdAt,
      );

      if (_isEditing) {
        await Provider.of<FarmerProvider>(context, listen: false).updateFarmer(
          farmer,
          createLoginAccount: !_hasExistingAccount && _createLoginAccount,
          accountPassword: _accountPasswordController.text.trim().isEmpty
              ? null
              : _accountPasswordController.text.trim(),
        );
      } else {
        await Provider.of<FarmerProvider>(context, listen: false).addFarmer(
          farmer,
          createLoginAccount: _createLoginAccount,
          accountPassword: _accountPasswordController.text.trim().isEmpty
              ? null
              : _accountPasswordController.text.trim(),
        );
      }

      if (!mounted) return;

      Helpers.showSnackBar(
        context,
        _isEditing
            ? 'Farmer updated successfully'
            : 'Farmer registered successfully',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(
        context,
        'Failed to save farmer: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Farmer' : 'Register Farmer'),
        backgroundColor: Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
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
                          radius: 42,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            size: 16,
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
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    if ((_profileImagePath ?? '').isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() => _profileImagePath = null);
                        },
                        child: const Text('Remove Picture'),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Farmer Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) => Validators.validateRequired(v, 'Name'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _villageController,
                decoration: InputDecoration(
                  labelText: 'Village',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => Validators.validateRequired(v, 'Village'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: Validators.validatePhone,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  helperText:
                      'Location permission will auto-fill address when available',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(Icons.location_on, color: Color(0xFF2E7D32)),
                  title: Text(_currentPosition == null
                      ? 'Capture Location'
                      : 'Location Captured'),
                  subtitle: _currentPosition != null
                      ? Text(
                          '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}')
                      : Text('Tap to grant permission and fetch GPS + address'),
                  trailing: Icon(Icons.gps_fixed),
                  onTap: _getLocation,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable farmer login'),
                        subtitle: Text(
                          _hasExistingAccount
                              ? 'Farmer can already sign in using mobile number and password'
                              : 'Create login credentials for the farmer',
                        ),
                        value: _hasExistingAccount ? true : _createLoginAccount,
                        onChanged: _hasExistingAccount
                            ? null
                            : (value) {
                                setState(() => _createLoginAccount = value);
                              },
                      ),
                      if (!_hasExistingAccount && _createLoginAccount)
                        TextFormField(
                          controller: _accountPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Initial Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            helperText:
                                'Farmer will sign in using the mobile number above',
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (!_createLoginAccount) {
                              return null;
                            }
                            return Validators.validatePassword(value);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveFarmer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditing ? 'Update Farmer' : 'Register Farmer',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
