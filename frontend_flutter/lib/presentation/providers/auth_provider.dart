import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _isLocked = false;
  bool _isMpinEnabled = false;
  int _mpinTimeoutMinutes = 1;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isLocked => _isLocked;
  bool get isSignedIn => _user != null && (_user?.token?.isNotEmpty ?? false);
  bool get isMpinEnabled => _isMpinEnabled;
  int get mpinTimeoutMinutes => _mpinTimeoutMinutes;
  bool get isFarmer => _user?.role == 'farmer';
  bool get isFieldWorker =>
      _user?.role == 'fieldworker' || _user?.role == 'admin';

  AuthProvider() {
    ApiService.configureAuth(
      onRefreshToken: _repository.refreshAccessToken,
      onSessionExpired: _handleSessionExpired,
    );
  }

  Future<void> initializeSession() async {
    _isInitializing = true;
    notifyListeners();

    try {
      _user = await _repository.getSavedUser();
      _isMpinEnabled = await _repository.isMpinEnabled();
      _mpinTimeoutMinutes = await _repository.getMpinTimeoutMinutes();

      final token = _user?.token?.trim();
      if (token != null && token.isNotEmpty) {
        ApiService.setToken(token);
      }

      _isLocked = _user != null &&
          _isMpinEnabled &&
          await _repository.shouldRequireMpin(_mpinTimeoutMinutes);
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _repository.login(identifier, password);
      _isMpinEnabled = await _repository.isMpinEnabled();
      _mpinTimeoutMinutes = await _repository.getMpinTimeoutMinutes();
      _isLocked = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _repository.register(name, email, password);
      _isMpinEnabled = await _repository.isMpinEnabled();
      _mpinTimeoutMinutes = await _repository.getMpinTimeoutMinutes();
      _isLocked = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    _user = await _repository.updateProfile(
      updatedUser.copyWith(
        token: _user?.token,
        role: _user?.role,
        farmerId: _user?.farmerId,
      ),
    );
    notifyListeners();
  }

  Future<void> updateMpinSettings({
    required bool enabled,
    String? mpin,
    required int timeoutMinutes,
  }) async {
    await _repository.updateMpinSettings(
      enabled: enabled,
      mpin: mpin,
      timeoutMinutes: timeoutMinutes,
    );

    _isMpinEnabled = enabled;
    _mpinTimeoutMinutes = timeoutMinutes;
    if (!enabled) {
      _isLocked = false;
    }
    notifyListeners();
  }

  Future<bool> unlockWithMpin(String mpin) async {
    final isValid = await _repository.validateMpin(mpin);
    if (!isValid) {
      return false;
    }

    _isLocked = false;
    await _repository.clearBackgroundedAt();
    notifyListeners();
    return true;
  }

  Future<void> handleAppLifecycleState(AppLifecycleState state) async {
    if (_user == null || !_isMpinEnabled) {
      return;
    }

    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      await _repository.saveBackgroundedAt(DateTime.now());
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _isLocked = await _repository.shouldRequireMpin(_mpinTimeoutMinutes);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    _isLocked = false;
    notifyListeners();
  }

  Future<void> _handleSessionExpired() async {
    await _repository.logout();
    _user = null;
    _isLocked = false;
    notifyListeners();
  }
}
