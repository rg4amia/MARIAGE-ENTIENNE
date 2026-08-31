// Vues de la console d'exploitation. Ces objets ne correspondent à aucune
// table : la base les compose déjà agrégés, pour ne pas ouvrir chaque table
// à un rôle privilégié.

class AdminOrganization {
  final String id;
  final String name;
  final String slug;
  final String? ownerEmail;
  final String? planId;
  final String? planName;
  final String status;
  final int events;
  final int members;
  final int guests;
  final int invitationsSent;
  final DateTime? createdAt;

  const AdminOrganization({
    required this.id,
    required this.name,
    required this.slug,
    this.ownerEmail,
    this.planId,
    this.planName,
    required this.status,
    required this.events,
    required this.members,
    required this.guests,
    required this.invitationsSent,
    this.createdAt,
  });

  factory AdminOrganization.fromJson(Map<String, dynamic> json) {
    return AdminOrganization(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Sans nom',
      slug: json['slug'] as String? ?? '',
      ownerEmail: json['owner_email'] as String?,
      planId: json['plan_id'] as String?,
      planName: json['plan_name'] as String?,
      status: json['status'] as String? ?? 'active',
      events: _int(json['events']),
      members: _int(json['members']),
      guests: _int(json['guests']),
      invitationsSent: _int(json['invitations_sent']),
      createdAt: _date(json['created_at']),
    );
  }

  /// Un compte suspendu, impayé ou résilié ne peut plus rien envoyer.
  bool get isBlocked =>
      status == 'past_due' || status == 'canceled' || status == 'suspended';

  String get statusLabel => switch (status) {
    'trialing' => 'Essai',
    'active' => 'Actif',
    'past_due' => 'Impayé',
    'canceled' => 'Résilié',
    'suspended' => 'Suspendu',
    _ => status,
  };
}

class AdminEvent {
  final String id;
  final String title;
  final String slug;
  final String organizationId;
  final String organizationName;
  final int guests;
  final int tables;
  final int invitationsSent;
  final int maxInvitations;
  final DateTime? createdAt;

  const AdminEvent({
    required this.id,
    required this.title,
    required this.slug,
    required this.organizationId,
    required this.organizationName,
    required this.guests,
    required this.tables,
    required this.invitationsSent,
    required this.maxInvitations,
    this.createdAt,
  });

  factory AdminEvent.fromJson(Map<String, dynamic> json) {
    return AdminEvent(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Mariage',
      slug: json['slug'] as String? ?? '',
      organizationId: json['organization_id'] as String? ?? '',
      organizationName: json['organization_name'] as String? ?? '',
      guests: _int(json['guests']),
      tables: _int(json['tables']),
      invitationsSent: _int(json['invitations_sent']),
      maxInvitations: _int(json['max_invitations'], fallback: -1),
      createdAt: _date(json['created_at']),
    );
  }

  String get quotaLabel =>
      maxInvitations == -1 ? '$invitationsSent envois' : '$invitationsSent / $maxInvitations';
}

class AdminMembership {
  final String organizationName;
  final String role;
  final String status;

  const AdminMembership({
    required this.organizationName,
    required this.role,
    required this.status,
  });

  factory AdminMembership.fromJson(Map<String, dynamic> json) {
    return AdminMembership(
      organizationName: json['organization_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class AdminAccount {
  final String id;
  final String? email;
  final bool isPlatformAdmin;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;
  final List<AdminMembership> memberships;

  const AdminAccount({
    required this.id,
    this.email,
    required this.isPlatformAdmin,
    this.createdAt,
    this.lastSignInAt,
    this.memberships = const [],
  });

  factory AdminAccount.fromJson(Map<String, dynamic> json) {
    return AdminAccount(
      id: json['id'] as String,
      email: json['email'] as String?,
      isPlatformAdmin: json['is_platform_admin'] == true,
      createdAt: _date(json['created_at']),
      lastSignInAt: _date(json['last_sign_in_at']),
      memberships: ((json['memberships'] as List?) ?? const [])
          .map((row) => AdminMembership.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(),
    );
  }

  /// Un compte qui ne s'est jamais connecté n'a pas terminé son inscription.
  bool get neverSignedIn => lastSignInAt == null;
}

class AdminAction {
  final String action;
  final String targetType;
  final String? actorEmail;
  final Map<String, dynamic> details;
  final DateTime? createdAt;

  const AdminAction({
    required this.action,
    required this.targetType,
    this.actorEmail,
    this.details = const {},
    this.createdAt,
  });

  factory AdminAction.fromJson(Map<String, dynamic> json) {
    return AdminAction(
      action: json['action'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      actorEmail: json['actor_email'] as String?,
      details: Map<String, dynamic>.from(json['details'] as Map? ?? const {}),
      createdAt: _date(json['created_at']),
    );
  }

  String get label => switch (action) {
    'set_plan' => 'Changement de forfait',
    'set_status' => 'Changement de statut',
    'grant_invitations' => 'Envois offerts',
    _ => action,
  };

  String get summary {
    final reason = details['reason'] as String?;
    final change = switch (action) {
      'set_plan' || 'set_status' => '${details['from']} → ${details['to']}',
      'grant_invitations' => '+${details['extra']} envois',
      _ => '',
    };
    return [change, reason].where((p) => p != null && p.isNotEmpty).join(' — ');
  }
}

int _int(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value as String);
