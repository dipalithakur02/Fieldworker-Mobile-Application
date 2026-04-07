import 'dart:convert';

import '../../core/services/api_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  static const String _userKey = 'current_user';
  static const String _mpinEnabledKey = 'mpin_enabled';
  static const String _mpinTimeoutKey = 'mpin_timeout_minutes';
  static const String _lastBackgroundedAtKey = 'last_backgrounded_at';

  Future<UserModel> login(String identifier, String password) async {
    final response = await ApiService.post('/auth/login', {
      'identifier': identifier,
      'password': password,
    });

    final user = UserModel.fromJson(response.data['data']['user']);
    final accessToken =
        response.data['data']['accessToken'] ?? response.data['data']['token'];
    final refreshToken = response.data['data']['refreshToken'];

    final mergedUser =
        await _mergeWithSavedProfile(user.copyWith(token: accessToken));
    await _saveSession(
      mergedUser,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    ApiService.setToken(accessToken);

    return mergedUser;
  }

  Future<UserModel> register(String name, String email, String password) async {
    final response = await ApiService.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });

    final user = UserModel.fromJson(response.data['data']['user']);
    final accessToken =
        response.data['data']['accessToken'] ?? response.data['data']['token'];
    final refreshToken = response.data['data']['refreshToken'];

    final mergedUser =
        await _mergeWithSavedProfile(user.copyWith(token: accessToken));
    await _saveSession(
      mergedUser,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    ApiService.setToken(accessToken);

    return mergedUser;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = await SecureStorageService.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await ApiService.post('/auth/logout', {'refreshToken': refreshToken});
      } catch (_) {
        // Local cleanup still proceeds if the logout request cannot complete.
      }
    }

    await SecureStorageService.deleteAccessToken();
    await SecureStorageService.deleteRefreshToken();
    await prefs.remove(_userKey);
    await prefs.remove(_lastBackgroundedAtKey);
    ApiService.clearToken();
  }

  Future<String?> refreshAccessToken() async {
    final refreshToken = await SecureStorageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final response = await ApiService.post('/auth/refresh', {
      'refreshToken': refreshToken,
    });

    final data = response.data['data'] as Map<String, dynamic>;
    final accessToken = data['accessToken'] ?? data['token'];
    final rotatedRefreshToken = data['refreshToken'] ?? refreshToken;
    final updatedUser = await _mergeWithSavedProfile(
      UserModel.fromJson(data['user']).copyWith(token: accessToken),
    );

    await _saveSession(
      updatedUser,
      accessToken: accessToken,
      refreshToken: rotatedRefreshToken,
    );
    ApiService.setToken(accessToken);

    return accessToken;
  }

  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await SecureStorageService.getAccessToken();
    final rawUser = prefs.getString(_userKey);

    if (token == null || token.isEmpty) {
      return null;
    }

    if (rawUser == null || rawUser.isEmpty) {
      return UserModel(
        name: 'Field Worker',
        email: '',
        role: 'fieldworker',
        profileImagePath: null,
        token: token,
      );
    }

    final decoded = jsonDecode(rawUser) as Map<String, dynamic>;
    return UserModel.fromJson(decoded).copyWith(token: token);
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    final token = user.token?.trim();
    if (token != null && token.isNotEmpty) {
      await SecureStorageService.saveAccessToken(token);
      ApiService.setToken(token);
    }
  }

  Future<UserModel> updateProfile(UserModel user) async {
    final response = await ApiService.put('/auth/profile', {
      'name': user.name,
      'email': user.email.isEmpty ? null : user.email,
      'mobile': user.phone,
    });

    final updatedUser =
        UserModel.fromJson(response.data['data']['user']).copyWith(
      token: user.token,
      profileImagePath: user.profileImagePath,
    );
    await saveUser(updatedUser);
    return updatedUser;
  }

  Future<bool> isMpinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mpinEnabledKey) ?? false;
  }

  Future<int> getMpinTimeoutMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final timeout = prefs.getInt(_mpinTimeoutKey) ?? 1;
    return timeout == 2 ? 2 : 1;
  }

  Future<void> updateMpinSettings({
    required bool enabled,
    String? mpin,
    required int timeoutMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mpinEnabledKey, enabled);
    await prefs.setInt(_mpinTimeoutKey, timeoutMinutes == 2 ? 2 : 1);

    if (!enabled) {
      await SecureStorageService.deleteMpin();
      await prefs.remove(_lastBackgroundedAtKey);
      return;
    }

    if (mpin != null && mpin.isNotEmpty) {
      await SecureStorageService.saveMpin(mpin);
    }
  }

  Future<bool> validateMpin(String mpin) async {
    return await SecureStorageService.getMpin() == mpin;
  }

  Future<void> saveBackgroundedAt(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackgroundedAtKey, timestamp.toIso8601String());
  }

  Future<void> clearBackgroundedAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastBackgroundedAtKey);
  }

  Future<bool> shouldRequireMpin(int timeoutMinutes) async {
    final prefs = await SharedPreferences.getInstance();
    final rawTimestamp = prefs.getString(_lastBackgroundedAtKey);

    if (rawTimestamp == null || rawTimestamp.isEmpty) {
      return false;
    }

    final backgroundedAt = DateTime.tryParse(rawTimestamp);
    if (backgroundedAt == null) {
      return false;
    }

    final elapsed = DateTime.now().difference(backgroundedAt);
    return elapsed.inMinutes >= timeoutMinutes;
  }

  Future<void> _saveSession(
    UserModel user, {
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.remove(_lastBackgroundedAtKey);
    await SecureStorageService.saveAccessToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await SecureStorageService.saveRefreshToken(refreshToken);
    }
  }

  Future<UserModel> _mergeWithSavedProfile(UserModel user) async {
    final savedUser = await getSavedUser();
    if (savedUser == null) {
      return user;
    }

    final isSameUser = (savedUser.id != null && savedUser.id == user.id) ||
        (savedUser.email.isNotEmpty && savedUser.email == user.email);

    if (!isSameUser) {
      return user;
    }

    return user.copyWith(
      phone: (user.phone == null || user.phone!.isEmpty)
          ? savedUser.phone
          : user.phone,
      farmerId: user.farmerId ?? savedUser.farmerId,
      profileImagePath: user.profileImagePath ?? savedUser.profileImagePath,
    );
  }
}
