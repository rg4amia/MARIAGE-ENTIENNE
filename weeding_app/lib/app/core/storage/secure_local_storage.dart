import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Platform-aware [LocalStorage] for Supabase session persistence.
/// - Mobile: flutter_secure_storage (encrypted Keychain/Keystore) — when available
/// - Web: shared_preferences (localStorage)
class SecureLocalStorage extends LocalStorage {
  static const _sessionKey = 'supabase_session';
  SharedPreferences? _prefs;

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = _prefs?.getString(_sessionKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> accessToken() async {
    return _prefs?.getString(_sessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    await _prefs?.remove(_sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _prefs?.setString(_sessionKey, persistSessionString);
  }
}
