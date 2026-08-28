class Guest {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String qrToken;
  final String status;
  final DateTime createdAt;

  Guest({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.qrToken,
    this.status = 'draft',
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  Guest copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? status,
    String? qrToken,
  }) {
    return Guest(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      qrToken: qrToken ?? this.qrToken,
      status: status ?? this.status,
      createdAt: createdAt,
    );
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
