class GuestMedia {
  final String id;
  final String guestId;
  final String mediaType; // 'audio' ou 'video'
  final String storagePath;
  final int durationSeconds;
  final bool isValid;
  final DateTime submittedAt;

  GuestMedia({
    required this.id,
    required this.guestId,
    required this.mediaType,
    required this.storagePath,
    required this.durationSeconds,
    this.isValid = false,
    DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  factory GuestMedia.fromJson(Map<String, dynamic> json) {
    return GuestMedia(
      id: json['id'] as String,
      guestId: json['guest_id'] as String,
      mediaType: json['media_type'] as String,
      storagePath: json['storage_path'] as String,
      durationSeconds: json['duration_seconds'] as int,
      isValid: json['is_valid'] as bool? ?? false,
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
      'duration_seconds': durationSeconds,
      'is_valid': isValid,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }

  String get durationFormatted {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
