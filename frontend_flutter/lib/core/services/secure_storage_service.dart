import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _mpinKey = 'mpin';

  static Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  static Future<void> deleteAccessToken() {
    return _storage.delete(key: _accessTokenKey);
  }

  static Future<void> saveRefreshToken(String token) {
    return _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  static Future<void> deleteRefreshToken() {
    return _storage.delete(key: _refreshTokenKey);
  }

  static Future<void> saveMpin(String mpin) {
    return _storage.write(key: _mpinKey, value: mpin);
  }

  static Future<String?> getMpin() {
    return _storage.read(key: _mpinKey);
  }

  static Future<void> deleteMpin() {
    return _storage.delete(key: _mpinKey);
  }
}
