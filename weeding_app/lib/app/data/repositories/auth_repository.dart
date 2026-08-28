import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone},
    );

    return response;
  }

  Future<Map<String, dynamic>> createSaasWorkspace({
    required String organizationName,
    required String eventTitle,
    required String brideName,
    required String groomName,
    DateTime? eventDate,
    String countryCode = 'CI',
    String timezone = 'Africa/Abidjan',
  }) async {
    final response = await _client.rpc(
      'create_saas_workspace',
      params: {
        'p_organization_name': organizationName,
        'p_event_title': eventTitle,
        'p_bride_name': brideName,
        'p_groom_name': groomName,
        'p_event_date': eventDate?.toUtc().toIso8601String(),
        'p_country_code': countryCode,
        'p_timezone': timezone,
      },
    );

    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Profile?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  Future<Profile?> updateProfile({
    required String fullName,
    String? phone,
  }) async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .update({'full_name': fullName, 'phone': phone})
        .eq('id', user.id)
        .select()
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }
}
