import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  /// Supabase project URL
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';

  /// Supabase anonymous (public) key
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Default wedding event ID (single-tenant bootstrap)
  static const String eventId = '00000000-0000-0000-0000-000000000001';

  /// Public guest portal base URL
  static String get guestPortalUrl =>
      dotenv.env['GUEST_PORTAL_URL'] ?? 'https://rg4amia.github.io/MARIAGE-ENTIENNE/';

  /// Returns true when both URL and key are populated.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
