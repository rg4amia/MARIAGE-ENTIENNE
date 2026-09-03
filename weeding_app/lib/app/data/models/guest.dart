class Guest {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String qrToken;
  final String status;

  /// Réponse de l'invité à l'invitation : 'pending', 'confirmed' ou 'declined'.
  /// La réponse est enregistrée depuis le portail, avant l'attribution d'une
  /// table : le couple place ensuite les invités ayant confirmé.
  final String rsvpStatus;
  final DateTime? rsvpRespondedAt;
  final DateTime createdAt;

  Guest({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.qrToken,
    this.status = 'draft',
    this.rsvpStatus = 'pending',
    this.rsvpRespondedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      qrToken: json['qr_token'] as String,
      status: json['status'] as String? ?? 'draft',
      rsvpStatus: json['rsvp_status'] as String? ?? 'pending',
      rsvpRespondedAt: json['rsvp_responded_at'] != null
          ? DateTime.parse(json['rsvp_responded_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'qr_token': qrToken,
      'status': status,
      'rsvp_status': rsvpStatus,
      'rsvp_responded_at': rsvpRespondedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Guest copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? status,
    String? qrToken,
    String? rsvpStatus,
    DateTime? rsvpRespondedAt,
  }) {
    return Guest(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      qrToken: qrToken ?? this.qrToken,
      status: status ?? this.status,
      rsvpStatus: rsvpStatus ?? this.rsvpStatus,
      rsvpRespondedAt: rsvpRespondedAt ?? this.rsvpRespondedAt,
      createdAt: createdAt,
    );
  }

  bool get hasRsvpResponded =>
      rsvpStatus == 'confirmed' || rsvpStatus == 'declined';

  bool get isRsvpConfirmed => rsvpStatus == 'confirmed';

  String get rsvpStatusLabel {
    switch (rsvpStatus) {
      case 'confirmed':
        return 'Présence confirmée';
      case 'declined':
        return 'Absence signalée';
      default:
        return 'En attente de réponse';
    }
  }

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.length >= 2
        ? fullName.substring(0, 2).toUpperCase()
        : fullName.toUpperCase();
  }

  String get statusLabel {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'pending_media':
        return 'En attente';
      case 'media_uploaded':
        return 'Média reçu';
      case 'card_unlocked':
        return 'Carte débloquée';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }
}
