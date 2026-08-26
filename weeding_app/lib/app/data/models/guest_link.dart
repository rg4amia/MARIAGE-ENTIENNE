class GuestLink {
  final String id;
  final String shortCode;
  final String guestToken;
  final String guestId;
  final bool isActive;
  final int scanCount;
  final DateTime? lastScannedAt;
  final DateTime createdAt;

  GuestLink({
    required this.id,
    required this.shortCode,
    required this.guestToken,
    required this.guestId,
    this.isActive = true,
    this.scanCount = 0,
    this.lastScannedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory GuestLink.fromJson(Map<String, dynamic> json) {
    return GuestLink(
      id: json['id'] as String,
      shortCode: json['short_code'] as String,
      guestToken: json['guest_token'] as String,
      guestId: json['guest_id'] as String,
      isActive: json['is_active'] as bool? ?? true,
      scanCount: json['scan_count'] as int? ?? 0,
      lastScannedAt: json['last_scanned_at'] != null
          ? DateTime.parse(json['last_scanned_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'short_code': shortCode,
      'guest_token': guestToken,
      'guest_id': guestId,
      'is_active': isActive,
      'scan_count': scanCount,
      'last_scanned_at': lastScannedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Full invite URL (will be constructed using the Supabase project URL)
  String getInviteUrl(String supabaseUrl) {
    // Extract project ref from supabase URL
    // https://xxx.supabase.co → xxx.supabase.co
    final host = Uri.parse(supabaseUrl).host;
    return 'https://$host/functions/v1/invite/$shortCode';
  }

  GuestLink copyWith({bool? isActive, int? scanCount}) {
    return GuestLink(
      id: id,
      shortCode: shortCode,
      guestToken: guestToken,
      guestId: guestId,
      isActive: isActive ?? this.isActive,
      scanCount: scanCount ?? this.scanCount,
      lastScannedAt: lastScannedAt,
      createdAt: createdAt,
    );
  }
}
