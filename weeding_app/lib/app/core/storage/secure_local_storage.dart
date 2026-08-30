import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Platform-aware [LocalStorage] for Supabase session persistence.
/// - Mobile/desktop: flutter_secure_storage (encrypted Keychain/Keystore)
/// - Web: shared_preferences (no secure enclave available in the browser)
class SecureLocalStorage extends LocalStorage {
  static const _sessionKey = 'supabase_session';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  SharedPreferences? _prefs;

  @override
  Future<void> initialize() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = await accessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> accessToken() async {
    if (kIsWeb) return _prefs?.getString(_sessionKey);
    return _secureStorage.read(key: _sessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    if (kIsWeb) {
      await _prefs?.remove(_sessionKey);
    } else {
      await _secureStorage.delete(key: _sessionKey);
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (kIsWeb) {
      await _prefs?.setString(_sessionKey, persistSessionString);
    } else {
      await _secureStorage.write(key: _sessionKey, value: persistSessionString);
    }
  }
}
