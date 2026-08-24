class Invitation {
  final String id;
  final String guestId;
  final String invitationCode;
  final String? qrCodeUrl;
  final String? cardUrl;
  final bool isUnlocked;
  final DateTime createdAt;

  Invitation({
    required this.id,
    required this.guestId,
    required this.invitationCode,
    this.qrCodeUrl,
    this.cardUrl,
    this.isUnlocked = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      guestId: json['guest_id'] as String,
      invitationCode: json['invitation_code'] as String,
      qrCodeUrl: json['qr_code_url'] as String?,
      cardUrl: json['card_url'] as String?,
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_id': guestId,
      'invitation_code': invitationCode,
      'qr_code_url': qrCodeUrl,
      'card_url': cardUrl,
      'is_unlocked': isUnlocked,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Invitation copyWith({String? qrCodeUrl, String? cardUrl, bool? isUnlocked}) {
    return Invitation(
      id: id,
      guestId: guestId,
      invitationCode: invitationCode,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      cardUrl: cardUrl ?? this.cardUrl,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      createdAt: createdAt,
    );
  }
}
