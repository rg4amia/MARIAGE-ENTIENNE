import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/platform_admin.dart';

/// Accès à la console d'exploitation. Chaque fonction appelée vérifie
/// elle-même la qualité d'exploitant côté base : l'app ne fait qu'afficher.
class AdminRepository {
  AdminRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<bool> isPlatformAdmin() async {
    final response = await _client.rpc('is_platform_admin');
    return response == true;
  }

  Future<List<AdminOrganization>> listOrganizations({String? search}) async {
    final response = await _client.rpc(
      'admin_list_organizations',
      params: {'p_search': _trimmed(search)},
    );
    return _map(response, AdminOrganization.fromJson);
  }

  Future<List<AdminEvent>> listEvents({
    String? organizationId,
    String? search,
  }) async {
    final response = await _client.rpc(
      'admin_list_events',
      params: {
        'p_organization_id': organizationId,
        'p_search': _trimmed(search),
      },
    );
    return _map(response, AdminEvent.fromJson);
  }

  Future<List<AdminAccount>> listAccounts({String? search}) async {
    final response = await _client.rpc(
      'admin_list_accounts',
      params: {'p_search': _trimmed(search)},
    );
    return _map(response, AdminAccount.fromJson);
  }

  Future<List<AdminAction>> recentActions() async {
    final response = await _client.rpc('admin_recent_actions');
    return _map(response, AdminAction.fromJson);
  }

  Future<void> setOrganizationPlan({
    required String organizationId,
    required String planId,
    required String reason,
  }) async {
    await _client.rpc(
      'admin_set_organization_plan',
      params: {
        'p_organization_id': organizationId,
        'p_plan_id': planId,
        'p_reason': reason,
      },
    );
  }

  Future<void> setOrganizationStatus({
    required String organizationId,
    required String status,
    required String reason,
  }) async {
    await _client.rpc(
      'admin_set_organization_status',
      params: {
        'p_organization_id': organizationId,
        'p_status': status,
        'p_reason': reason,
      },
    );
  }

  Future<void> grantInvitations({
    required String eventId,
    required int extra,
    required String reason,
  }) async {
    await _client.rpc(
      'admin_grant_invitations',
      params: {
        'p_event_id': eventId,
        'p_extra': extra,
        'p_reason': reason,
      },
    );
  }

  static String? _trimmed(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<T> _map<T>(
    Object? response,
    T Function(Map<String, dynamic>) build,
  ) {
    return ((response as List?) ?? const [])
        .map((row) => build(Map<String, dynamic>.from(row as Map)))
        .toList();
  }
}
