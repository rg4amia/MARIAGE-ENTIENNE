import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Custom [LocalStorage] implementation using flutter_secure_storage.
/// Sessions are encrypted in the device's secure enclave / Keychain / Keystore.
class SecureLocalStorage extends LocalStorage {
  final _storage = const FlutterSecureStorage();
  static const _sessionKey = 'supabase_session';

  @override
  Future<void> initialize() async {
    // No-op: FlutterSecureStorage initializes on first use
  }

  @override
  Future<bool> hasAccessToken() async {
    final token = await _storage.read(key: _sessionKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> accessToken() async {
    return await _storage.read(key: _sessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: _sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(key: _sessionKey, value: persistSessionString);
  }
}
