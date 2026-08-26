class Invitation {
  final String id;
  final String guestId;
  final String tableId;
  final String chairId;
  final String invitationCode;
  final String webUrl;
  final String deepLink;
  final String qrPayload;
  final String? pngStoragePath;
  final String? pdfStoragePath;
  final bool isUnlocked;
  final DateTime createdAt;

  Invitation({
    required this.id,
    required this.guestId,
    required this.tableId,
    required this.chairId,
    required this.invitationCode,
    required this.webUrl,
    required this.deepLink,
    required this.qrPayload,
    this.pngStoragePath,
    this.pdfStoragePath,
    this.isUnlocked = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'] as String,
      guestId: json['guest_id'] as String,
      tableId: json['table_id'] as String,
      chairId: json['chair_id'] as String,
      invitationCode: json['invitation_code'] as String,
      webUrl: json['web_url'] as String,
      deepLink: json['deep_link'] as String,
      qrPayload: json['qr_payload'] as String,
      pngStoragePath: json['png_storage_path'] as String?,
      pdfStoragePath: json['pdf_storage_path'] as String?,
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
      'table_id': tableId,
      'chair_id': chairId,
      'invitation_code': invitationCode,
      'web_url': webUrl,
      'deep_link': deepLink,
      'qr_payload': qrPayload,
      'png_storage_path': pngStoragePath,
      'pdf_storage_path': pdfStoragePath,
      'is_unlocked': isUnlocked,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Invitation copyWith({
    String? pngStoragePath,
    String? pdfStoragePath,
    bool? isUnlocked,
  }) {
    return Invitation(
      id: id,
      guestId: guestId,
      tableId: tableId,
      chairId: chairId,
      invitationCode: invitationCode,
      webUrl: webUrl,
      deepLink: deepLink,
      qrPayload: qrPayload,
      pngStoragePath: pngStoragePath ?? this.pngStoragePath,
      pdfStoragePath: pdfStoragePath ?? this.pdfStoragePath,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      createdAt: createdAt,
    );
  }
}
