class EntranceQr {
  final String id;
  final String eventId;
  final String code;
  final String url;
  final bool isActive;
  final int scanCount;
  final int checkInCount;
  final DateTime? lastScannedAt;
  final DateTime createdAt;

  const EntranceQr({
    required this.id,
    required this.eventId,
    required this.code,
    required this.url,
    required this.isActive,
    required this.scanCount,
    required this.checkInCount,
    this.lastScannedAt,
    required this.createdAt,
  });

  factory EntranceQr.fromJson(Map<String, dynamic> json) {
    return EntranceQr(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      code: json['code'] as String,
      url: json['url'] as String,
      isActive: json['is_active'] as bool? ?? true,
      scanCount: json['scan_count'] as int? ?? 0,
      checkInCount: json['check_in_count'] as int? ?? 0,
      lastScannedAt: json['last_scanned_at'] == null
          ? null
          : DateTime.parse(json['last_scanned_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
