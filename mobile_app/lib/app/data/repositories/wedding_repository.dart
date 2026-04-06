import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/services/supabase_service.dart';
import '../models/invitation_models.dart';

class WeddingRepository extends GetxService {
  final _uuid = const Uuid();
  final SupabaseService _supabase = Get.find<SupabaseService>();
  final List<WeddingTable> _tables = [];
  final List<WeddingGuest> _guests = [];
  final List<GuestInvitation> _invitations = [];

  late WeddingEvent _event;

  WeddingEvent get event => _event;
  List<WeddingTable> get tables => List.unmodifiable(_tables);
  List<WeddingGuest> get guests => List.unmodifiable(_guests);
  List<GuestInvitation> get invitations => List.unmodifiable(_invitations);
  bool get isRemoteConfigured => _supabase.isConfigured;

  Future<WeddingRepository> init() async {
    _event = const WeddingEvent(
      id: 'event-entienne',
      title: 'Mariage Entienne',
      brideName: 'Aimee',
      groomName: 'Entienne',
      location: 'Abidjan',
      eventDateLabel: 'Decembre 2026',
    );

    _seedDemoData();
    return this;
  }

  Future<WeddingTable> createTable({
    required String label,
    required int capacity,
  }) async {
    final tableId = _uuid.v4();
    final table = WeddingTable(
      id: tableId,
      label: label,
      capacity: capacity,
      chairs: List.generate(
        capacity,
        (index) =>
            ChairModel(id: _uuid.v4(), tableId: tableId, number: index + 1),
      ),
    );

    _tables.add(table);
    return table;
  }

  Future<WeddingGuest> createGuest({
    required String fullName,
    required String phone,
    required String email,
  }) async {
    final guest = WeddingGuest(
      id: _uuid.v4(),
      fullName: fullName,
      phone: phone,
      email: email,
      status: GuestStatus.draft,
    );

    _guests.add(guest);
    return guest;
  }

  List<ChairModel> availableChairs({String? includeGuestId}) {
    return _tables
        .expand((table) => table.chairs)
        .where((chair) => !chair.isAssigned || chair.guestId == includeGuestId)
        .toList(growable: false);
  }

  ChairModel? chairForGuest(String guestId) {
    for (final table in _tables) {
      for (final chair in table.chairs) {
        if (chair.guestId == guestId) {
          return chair;
        }
      }
    }
    return null;
  }

  WeddingTable? tableForChair(String chairId) {
    for (final table in _tables) {
      if (table.chairs.any((chair) => chair.id == chairId)) {
        return table;
      }
    }
    return null;
  }

  GuestInvitation? invitationForGuest(String guestId) {
    return _invitations.cast<GuestInvitation?>().firstWhereOrNull(
      (item) => item?.guestId == guestId,
    );
  }

  Future<GuestInvitation> assignGuestToChair({
    required String guestId,
    required String chairId,
  }) async {
    final guestIndex = _guests.indexWhere((guest) => guest.id == guestId);
    if (guestIndex == -1) {
      throw StateError('Invite introuvable.');
    }

    _clearExistingSeat(guestId);

    WeddingTable? targetTable;
    ChairModel? targetChair;

    for (var tableIndex = 0; tableIndex < _tables.length; tableIndex++) {
      final table = _tables[tableIndex];
      final chairIndex = table.chairs.indexWhere(
        (chair) => chair.id == chairId,
      );
      if (chairIndex == -1) {
        continue;
      }

      final chair = table.chairs[chairIndex];
      if (chair.isAssigned && chair.guestId != guestId) {
        throw StateError('Cette chaise est deja occupee.');
      }

      final updatedChairs = [...table.chairs];
      targetChair = chair.copyWith(guestId: guestId);
      updatedChairs[chairIndex] = targetChair;
      targetTable = table.copyWith(chairs: updatedChairs);
      _tables[tableIndex] = targetTable;
      break;
    }

    if (targetTable == null || targetChair == null) {
      throw StateError('Chaise introuvable.');
    }

    _guests[guestIndex] = _guests[guestIndex].copyWith(
      status: GuestStatus.pendingMedia,
    );

    final existingIndex = _invitations.indexWhere(
      (item) => item.guestId == guestId,
    );
    final token = existingIndex == -1
        ? _uuid.v4().replaceAll('-', '')
        : _invitations[existingIndex].token;
    final invitation = GuestInvitation(
      id: existingIndex == -1 ? _uuid.v4() : _invitations[existingIndex].id,
      guestId: guestId,
      guestName: _guests[guestIndex].fullName,
      tableId: targetTable.id,
      tableLabel: targetTable.label,
      chairId: targetChair.id,
      chairNumber: targetChair.number,
      token: token,
      invitationCode: token.substring(0, 8).toUpperCase(),
      webUrl: AppConfig.buildWebGuestUri(token).toString(),
      deepLink: AppConfig.buildDeepLink(token).toString(),
      isUnlocked: existingIndex == -1
          ? false
          : _invitations[existingIndex].isUnlocked,
      pngStoragePath: existingIndex == -1
          ? null
          : _invitations[existingIndex].pngStoragePath,
      pdfStoragePath: existingIndex == -1
          ? null
          : _invitations[existingIndex].pdfStoragePath,
      mediaSubmissions: existingIndex == -1
          ? []
          : _invitations[existingIndex].mediaSubmissions,
    );

    if (existingIndex == -1) {
      _invitations.add(invitation);
    } else {
      _invitations[existingIndex] = invitation;
    }

    return invitation;
  }

  Future<GuestInvitation?> findInvitationByToken(String token) async {
    if (_supabase.isConfigured) {
      final response = await _supabase.client.rpc(
        'get_invitation_by_token',
        params: {'p_token': token},
      );
      if (response != null) {
        return _mapRemoteInvitation(Map<String, dynamic>.from(response));
      }
    }

    return _invitations.cast<GuestInvitation?>().firstWhereOrNull(
      (item) => item?.token == token,
    );
  }

  Future<MediaSubmission> submitGuestMedia({
    required String token,
    required MediaType type,
    required double clientDurationSeconds,
    double? serverDurationSeconds,
    String? localReference,
  }) async {
    if (_supabase.isConfigured) {
      final response = await _supabase.client.rpc(
        'submit_guest_media_by_token',
        params: {
          'p_token': token,
          'p_media_type': type.name,
          'p_storage_path':
              localReference ?? 'browser://${type.name}/${_uuid.v4()}',
          'p_client_duration_seconds': clientDurationSeconds,
          'p_server_duration_seconds':
              serverDurationSeconds ?? clientDurationSeconds,
        },
      );

      if (response == null) {
        throw StateError('La validation distante a echoue.');
      }

      final invitation = _mapRemoteInvitation(
        Map<String, dynamic>.from(response),
      );
      return invitation.mediaSubmissions.isNotEmpty
          ? invitation.mediaSubmissions.last
          : MediaSubmission(
              id: _uuid.v4(),
              invitationId: invitation.id,
              guestId: invitation.guestId,
              type: type,
              clientDurationSeconds: clientDurationSeconds,
              serverDurationSeconds:
                  serverDurationSeconds ?? clientDurationSeconds,
              clientValidated: clientDurationSeconds >= 30,
              serverValidated:
                  (serverDurationSeconds ?? clientDurationSeconds) >= 30,
              localReference:
                  localReference ?? 'browser://${type.name}/${_uuid.v4()}',
              submittedAt: DateTime.now(),
            );
    }

    final invitationIndex = _invitations.indexWhere(
      (item) => item.token == token,
    );
    if (invitationIndex == -1) {
      throw StateError('Invitation introuvable.');
    }

    final invitation = _invitations[invitationIndex];
    final serverDuration = serverDurationSeconds ?? clientDurationSeconds;
    final submission = MediaSubmission(
      id: _uuid.v4(),
      invitationId: invitation.id,
      guestId: invitation.guestId,
      type: type,
      clientDurationSeconds: clientDurationSeconds,
      serverDurationSeconds: serverDuration,
      clientValidated: clientDurationSeconds >= 30,
      serverValidated: serverDuration >= 30,
      localReference: localReference ?? 'local://${type.name}/${_uuid.v4()}',
      submittedAt: DateTime.now(),
    );

    final updatedInvitation = invitation.copyWith(
      mediaSubmissions: [...invitation.mediaSubmissions, submission],
      isUnlocked: submission.isAccepted ? true : invitation.isUnlocked,
    );
    _invitations[invitationIndex] = updatedInvitation;

    final guestIndex = _guests.indexWhere(
      (guest) => guest.id == invitation.guestId,
    );
    if (guestIndex != -1) {
      _guests[guestIndex] = _guests[guestIndex].copyWith(
        status: submission.isAccepted
            ? GuestStatus.cardUnlocked
            : GuestStatus.mediaUploaded,
      );
    }

    return submission;
  }

  Future<GuestInvitation> attachGeneratedAssets({
    required String invitationId,
    required String pngStoragePath,
    required String pdfStoragePath,
  }) async {
    final index = _invitations.indexWhere((item) => item.id == invitationId);
    if (index == -1) {
      throw StateError('Invitation introuvable.');
    }

    final invitation = _invitations[index].copyWith(
      pngStoragePath: pngStoragePath,
      pdfStoragePath: pdfStoragePath,
    );
    _invitations[index] = invitation;
    return invitation;
  }

  void _clearExistingSeat(String guestId) {
    for (var tableIndex = 0; tableIndex < _tables.length; tableIndex++) {
      final table = _tables[tableIndex];
      var changed = false;
      final updatedChairs = table.chairs
          .map((chair) {
            if (chair.guestId == guestId) {
              changed = true;
              return chair.copyWith(clearGuest: true);
            }
            return chair;
          })
          .toList(growable: false);

      if (changed) {
        _tables[tableIndex] = table.copyWith(chairs: updatedChairs);
      }
    }
  }

  void _seedDemoData() {
    if (_tables.isNotEmpty || _guests.isNotEmpty) {
      return;
    }

    createTable(label: 'Famille', capacity: 6);
    createTable(label: 'Amis', capacity: 8);
    createGuest(
      fullName: 'Stephanie K.',
      phone: '+2250102030405',
      email: 'stephanie@example.com',
    );
    createGuest(
      fullName: 'Jean M.',
      phone: '+2250504030201',
      email: 'jean@example.com',
    );
  }

  GuestInvitation _mapRemoteInvitation(Map<String, dynamic> payload) {
    final eventPayload = Map<String, dynamic>.from(
      payload['event'] as Map? ??
          {
            'id': _event.id,
            'title': _event.title,
            'bride_name': _event.brideName,
            'groom_name': _event.groomName,
            'location': _event.location,
            'event_date_label': _event.eventDateLabel,
          },
    );

    _event = WeddingEvent(
      id: eventPayload['id']?.toString() ?? _event.id,
      title: eventPayload['title']?.toString() ?? _event.title,
      brideName: eventPayload['bride_name']?.toString() ?? _event.brideName,
      groomName: eventPayload['groom_name']?.toString() ?? _event.groomName,
      location: eventPayload['location']?.toString() ?? _event.location,
      eventDateLabel:
          eventPayload['event_date_label']?.toString() ?? _event.eventDateLabel,
    );

    final mediaList = (payload['media_submissions'] as List? ?? [])
        .map((item) => _mapRemoteMedia(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    final invitation = GuestInvitation(
      id: payload['id'].toString(),
      guestId: payload['guest_id'].toString(),
      guestName: payload['guest_name']?.toString() ?? '',
      tableId: payload['table_id'].toString(),
      tableLabel: payload['table_label']?.toString() ?? '',
      chairId: payload['chair_id'].toString(),
      chairNumber: _asInt(payload['chair_number']),
      token: payload['token']?.toString() ?? '',
      invitationCode: payload['invitation_code']?.toString() ?? '',
      webUrl: payload['web_url']?.toString() ?? '',
      deepLink: payload['deep_link']?.toString() ?? '',
      isUnlocked: payload['is_unlocked'] == true,
      pngStoragePath: payload['png_storage_path']?.toString(),
      pdfStoragePath: payload['pdf_storage_path']?.toString(),
      mediaSubmissions: mediaList,
    );

    final index = _invitations.indexWhere((item) => item.id == invitation.id);
    if (index == -1) {
      _invitations.add(invitation);
    } else {
      _invitations[index] = invitation;
    }

    return invitation;
  }

  MediaSubmission _mapRemoteMedia(Map<String, dynamic> payload) {
    return MediaSubmission(
      id: payload['id'].toString(),
      invitationId: payload['invitation_id']?.toString() ?? '',
      guestId: payload['guest_id']?.toString() ?? '',
      type: (payload['media_type']?.toString() ?? 'audio') == 'video'
          ? MediaType.video
          : MediaType.audio,
      clientDurationSeconds: _asDouble(payload['client_duration_seconds']),
      serverDurationSeconds: _asDouble(payload['server_duration_seconds']),
      clientValidated: payload['client_validated'] == true,
      serverValidated: payload['server_validated'] == true,
      localReference: payload['storage_path']?.toString() ?? '',
      submittedAt:
          DateTime.tryParse(payload['submitted_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
