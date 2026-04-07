import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../data/models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/avatar_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mpinController = TextEditingController();
  final _confirmMpinController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _mpinEnabled = false;
  int _timeoutMinutes = 1;
  bool _isSavingProfile = false;
  bool _isSavingSecurity = false;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';
    _profileImagePath = user?.profileImagePath;
    _mpinEnabled = auth.isMpinEnabled;
    _timeoutMinutes = auth.mpinTimeoutMinutes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mpinController.dispose();
    _confirmMpinController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSavingProfile = true);

    final auth = context.read<AuthProvider>();
    final currentUser = auth.user;
    final updatedUser = UserModel(
      id: currentUser?.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: currentUser?.role ?? 'fieldworker',
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      farmerId: currentUser?.farmerId,
      profileImagePath: _profileImagePath,
      token: currentUser?.token,
    );

    await auth.updateProfile(updatedUser);

    if (!mounted) {
      return;
    }

    setState(() => _isSavingProfile = false);
    Helpers.showSnackBar(context, 'Profile updated');
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

  Future<void> _saveSecurity() async {
    if (_mpinEnabled && !_securityFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSavingSecurity = true);

    final auth = context.read<AuthProvider>();
    final mpin = _mpinController.text.trim();

    await auth.updateMpinSettings(
      enabled: _mpinEnabled,
      mpin: mpin.isEmpty ? null : mpin,
      timeoutMinutes: _timeoutMinutes,
    );

    _mpinController.clear();
    _confirmMpinController.clear();

    if (!mounted) {
      return;
    }

    setState(() => _isSavingSecurity = false);
    Helpers.showSnackBar(
      context,
      _mpinEnabled ? 'MPIN settings updated' : 'MPIN disabled',
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) {
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String? _validateMpin(String? value) {
    if (!_mpinEnabled) {
      return null;
    }

    final currentMpinEnabled = context.read<AuthProvider>().isMpinEnabled;
    final trimmed = value?.trim() ?? '';
    final confirm = _confirmMpinController.text.trim();

    if (!currentMpinEnabled && trimmed.isEmpty) {
      return 'MPIN is required';
    }

    if (trimmed.isEmpty) {
      return null;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(trimmed)) {
      return 'MPIN must be exactly 4 digits';
    }

    if (confirm.isNotEmpty && confirm != trimmed) {
      return 'MPIN does not match';
    }

    return null;
  }

  String? _validateConfirmMpin(String? value) {
    if (!_mpinEnabled) {
      return null;
    }

    final mpin = _mpinController.text.trim();
    final confirm = value?.trim() ?? '';

    if (mpin.isEmpty) {
      return null;
    }

    if (confirm != mpin) {
      return 'Confirm MPIN must match';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isFarmer = user?.role == 'farmer';
    final roleLabel = isFarmer
        ? 'Farmer'
        : user?.role == 'admin'
            ? 'Admin'
            : 'Field Worker';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    AvatarView(
                      imagePath: _profileImagePath,
                      fallbackLabel: user?.name ?? roleLabel,
                      radius: 32,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickProfileImage,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(
                        _profileImagePath == null
                            ? 'Add Profile Picture'
                            : 'Change Profile Picture',
                      ),
                    ),
                    if ((_profileImagePath ?? '').isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() => _profileImagePath = null);
                        },
                        child: const Text('Remove Picture'),
                      ),
                    Text(
                      user?.name.isNotEmpty == true
                          ? user!.name
                          : isFarmer
                              ? 'Farmer'
                              : 'Field Worker',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((user?.email ?? '').isNotEmpty)
                      Text(
                        user!.email,
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Information',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) =>
                            Validators.validateRequired(value, 'Name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: isFarmer ? 'Email (Optional)' : 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return isFarmer ? null : 'Email is required';
                          }
                          return Validators.validateEmail(trimmed);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          return Validators.validatePhone(value.trim());
                        },
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      if (!isFarmer)
                        TextFormField(
                          initialValue: roleLabel,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
                          enabled: false,
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSavingProfile ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                          child: _isSavingProfile
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Save Profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _securityFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable MPIN lock'),
                        subtitle: const Text(
                          'Require MPIN after the app stays in background for 1 or 2 minutes',
                        ),
                        value: _mpinEnabled,
                        onChanged: (value) {
                          setState(() {
                            _mpinEnabled = value;
                            if (!value) {
                              _mpinController.clear();
                              _confirmMpinController.clear();
                            }
                          });
                        },
                      ),
                      if (_mpinEnabled) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: _timeoutMinutes,
                          decoration: const InputDecoration(
                            labelText: 'Lock after',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 minute')),
                            DropdownMenuItem(
                                value: 2, child: Text('2 minutes')),
                          ],
                          onChanged: (value) {
                            setState(() => _timeoutMinutes = value ?? 1);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _mpinController,
                          decoration: InputDecoration(
                            labelText:
                                context.read<AuthProvider>().isMpinEnabled
                                    ? 'New MPIN (optional)'
                                    : '4-digit MPIN',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          validator: _validateMpin,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmMpinController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm MPIN',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          validator: _validateConfirmMpin,
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSavingSecurity ? null : _saveSecurity,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                          ),
                          child: _isSavingSecurity
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Save Security Settings'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
