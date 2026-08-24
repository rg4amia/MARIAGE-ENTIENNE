enum GuestStatus { draft, pendingMedia, mediaUploaded, cardUnlocked }

enum MediaType { audio, video }

extension GuestStatusX on GuestStatus {
  String get label {
    switch (this) {
      case GuestStatus.draft:
        return 'Brouillon';
      case GuestStatus.pendingMedia:
        return 'En attente de media';
      case GuestStatus.mediaUploaded:
        return 'Media recu';
      case GuestStatus.cardUnlocked:
        return 'Carte debloquee';
    }
  }
}

class WeddingEvent {
  const WeddingEvent({
    required this.id,
    required this.title,
    required this.brideName,
    required this.groomName,
    required this.location,
    required this.eventDateLabel,
  });

  final String id;
  final String title;
  final String brideName;
  final String groomName;
  final String location;
  final String eventDateLabel;

  String get coupleLabel => '$brideName & $groomName';
  String get subtitle => '$location • $eventDateLabel';
}

class ChairModel {
  const ChairModel({
    required this.id,
    required this.tableId,
    required this.number,
    this.guestId,
  });

  final String id;
  final String tableId;
  final int number;
  final String? guestId;

  bool get isAssigned => guestId != null;

  ChairModel copyWith({
    String? id,
    String? tableId,
    int? number,
    String? guestId,
    bool clearGuest = false,
  }) {
    return ChairModel(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      number: number ?? this.number,
      guestId: clearGuest ? null : (guestId ?? this.guestId),
    );
  }
}

class WeddingTable {
  const WeddingTable({
    required this.id,
    required this.label,
    required this.capacity,
    required this.chairs,
  });

  final String id;
  final String label;
  final int capacity;
  final List<ChairModel> chairs;

  int get occupiedSeats => chairs.where((chair) => chair.isAssigned).length;

  WeddingTable copyWith({
    String? id,
    String? label,
    int? capacity,
    List<ChairModel>? chairs,
  }) {
    return WeddingTable(
      id: id ?? this.id,
      label: label ?? this.label,
      capacity: capacity ?? this.capacity,
      chairs: chairs ?? this.chairs,
    );
  }
}

class WeddingGuest {
  const WeddingGuest({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.status,
  });

  final String id;
  final String fullName;
  final String phone;
  final String email;
  final GuestStatus status;

  WeddingGuest copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? email,
    GuestStatus? status,
  }) {
    return WeddingGuest(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
    );
  }
}

class MediaSubmission {
  const MediaSubmission({
    required this.id,
    required this.invitationId,
    required this.guestId,
    required this.type,
    required this.clientDurationSeconds,
    required this.serverDurationSeconds,
    required this.clientValidated,
    required this.serverValidated,
    required this.localReference,
    required this.submittedAt,
  });

  final String id;
  final String invitationId;
  final String guestId;
  final MediaType type;
  final double clientDurationSeconds;
  final double serverDurationSeconds;
  final bool clientValidated;
  final bool serverValidated;
  final String localReference;
  final DateTime submittedAt;

  bool get isAccepted => clientValidated && serverValidated;
}

class GuestInvitation {
  const GuestInvitation({
    required this.id,
    required this.guestId,
    required this.guestName,
    required this.guestStatus,
    required this.tableId,
    required this.tableLabel,
    required this.chairId,
    required this.chairNumber,
    required this.token,
    required this.invitationCode,
    required this.webUrl,
    required this.deepLink,
    required this.isUnlocked,
    required this.pngStoragePath,
    required this.pdfStoragePath,
    required this.signedPngUrl,
    required this.signedPdfUrl,
    required this.mediaSubmissions,
  });

  final String id;
  final String guestId;
  final String guestName;
  final GuestStatus guestStatus;
  final String tableId;
  final String tableLabel;
  final String chairId;
  final int chairNumber;
  final String token;
  final String invitationCode;
  final String webUrl;
  final String deepLink;
  final bool isUnlocked;
  final String? pngStoragePath;
  final String? pdfStoragePath;
  final String? signedPngUrl;
  final String? signedPdfUrl;
  final List<MediaSubmission> mediaSubmissions;

  bool get hasSignedCardAssets =>
      (signedPngUrl?.isNotEmpty ?? false) ||
      (signedPdfUrl?.isNotEmpty ?? false);

  GuestInvitation copyWith({
    String? id,
    String? guestId,
    String? guestName,
    GuestStatus? guestStatus,
    String? tableId,
    String? tableLabel,
    String? chairId,
    int? chairNumber,
    String? token,
    String? invitationCode,
    String? webUrl,
    String? deepLink,
    bool? isUnlocked,
    String? pngStoragePath,
    String? pdfStoragePath,
    String? signedPngUrl,
    String? signedPdfUrl,
    List<MediaSubmission>? mediaSubmissions,
  }) {
    return GuestInvitation(
      id: id ?? this.id,
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      guestStatus: guestStatus ?? this.guestStatus,
      tableId: tableId ?? this.tableId,
      tableLabel: tableLabel ?? this.tableLabel,
      chairId: chairId ?? this.chairId,
      chairNumber: chairNumber ?? this.chairNumber,
      token: token ?? this.token,
      invitationCode: invitationCode ?? this.invitationCode,
      webUrl: webUrl ?? this.webUrl,
      deepLink: deepLink ?? this.deepLink,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      pngStoragePath: pngStoragePath ?? this.pngStoragePath,
      pdfStoragePath: pdfStoragePath ?? this.pdfStoragePath,
      signedPngUrl: signedPngUrl ?? this.signedPngUrl,
      signedPdfUrl: signedPdfUrl ?? this.signedPdfUrl,
      mediaSubmissions: mediaSubmissions ?? this.mediaSubmissions,
    );
  }
}
