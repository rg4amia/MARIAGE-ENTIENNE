import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class SupabaseService extends GetxService {
  SupabaseClient? _client;

  bool get isConfigured => _client != null;

  SupabaseClient get client {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Supabase n\'est pas configure. Fournissez SUPABASE_ANON_KEY.',
      );
    }
    return client;
  }

  Future<SupabaseService> init() async {
    if (!AppConfig.hasSupabaseCredentials) {
      return this;
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    _client = Supabase.instance.client;
    return this;
  }
}
