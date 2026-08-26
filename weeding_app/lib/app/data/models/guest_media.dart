class GuestMedia {
  final String id;
  final String guestId;
  final String mediaType; // 'audio' ou 'video'
  final String storagePath;
  final double clientDurationSeconds;
  final double? serverDurationSeconds;
  final bool clientValidated;
  final bool serverValidated;
  final DateTime submittedAt;

  GuestMedia({
    required this.id,
    required this.guestId,
    required this.mediaType,
    required this.storagePath,
    required this.clientDurationSeconds,
    this.serverDurationSeconds,
    this.clientValidated = false,
    this.serverValidated = false,
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  factory GuestMedia.fromJson(Map<String, dynamic> json) {
    return GuestMedia(
      id: json['id'] as String,
      guestId: json['guest_id'] as String,
      mediaType: json['media_type'] as String,
      storagePath: json['storage_path'] as String,
      clientDurationSeconds: (json['client_duration_seconds'] as num)
          .toDouble(),
      serverDurationSeconds: (json['server_duration_seconds'] as num?)
          ?.toDouble(),
      clientValidated: json['client_validated'] as bool? ?? false,
      serverValidated: json['server_validated'] as bool? ?? false,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guest_id': guestId,
      'media_type': mediaType,
      'storage_path': storagePath,
      'client_duration_seconds': clientDurationSeconds,
      'server_duration_seconds': serverDurationSeconds,
      'client_validated': clientValidated,
      'server_validated': serverValidated,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }

  String get durationFormatted {
    final durationSeconds = (serverDurationSeconds ?? clientDurationSeconds)
        .round();
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get isValid => clientValidated && serverValidated;
}
