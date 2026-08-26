import 'package:flutter_test/flutter_test.dart';
import 'package:weeding_app/app/data/models/guest.dart';
import 'package:weeding_app/app/data/models/invitation.dart';
import 'package:weeding_app/app/data/models/wedding_table.dart';
import 'package:weeding_app/app/data/models/chair.dart';
import 'package:weeding_app/app/data/models/guest_seat.dart';
import 'package:weeding_app/app/data/models/guest_media.dart';
import 'package:weeding_app/app/data/models/profile.dart';
import 'package:weeding_app/app/data/models/entrance_qr.dart';

void main() {
  group('Guest Model', () {
    test('fromJson creates Guest correctly', () {
      final json = {
        'id': 'test-id',
        'full_name': 'Jean Dupont',
        'phone': '+33612345678',
        'email': 'jean@test.com',
        'qr_token': 'token-abc-123',
        'status': 'draft',
        'created_at': '2025-01-15T10:00:00Z',
      };

      final guest = Guest.fromJson(json);

      expect(guest.id, 'test-id');
      expect(guest.fullName, 'Jean Dupont');
      expect(guest.phone, '+33612345678');
      expect(guest.email, 'jean@test.com');
      expect(guest.qrToken, 'token-abc-123');
      expect(guest.status, 'draft');
    });

    test('toJson serializes correctly', () {
      final guest = Guest(
        id: 'test-id',
        fullName: 'Jean Dupont',
        phone: '+33612345678',
        email: 'jean@test.com',
        qrToken: 'token-abc',
        status: 'draft',
      );

      final json = guest.toJson();

      expect(json['id'], 'test-id');
      expect(json['full_name'], 'Jean Dupont');
      expect(json['phone'], '+33612345678');
      expect(json['qr_token'], 'token-abc');
    });

    test('copyWith preserves unmodified fields', () {
      final guest = Guest(
        id: 'test-id',
        fullName: 'Jean Dupont',
        qrToken: 'token',
        status: 'draft',
      );

      final updated = guest.copyWith(fullName: 'Marie Dupont');

      expect(updated.fullName, 'Marie Dupont');
      expect(updated.id, 'test-id');
      expect(updated.qrToken, 'token');
      expect(updated.status, 'draft');
    });
  });

  group('Invitation Model', () {
    test('fromJson creates Invitation correctly', () {
      final json = {
        'id': 'inv-1',
        'guest_id': 'guest-1',
        'table_id': 'table-1',
        'chair_id': 'chair-1',
        'invitation_code': 'INV-2025-ABC123',
        'web_url': 'https://example.com/guest?token=abc',
        'deep_link': 'mariageentienne://guest/abc',
        'qr_payload': 'https://example.com/guest?token=abc',
        'is_unlocked': false,
        'created_at': '2025-01-15T10:00:00Z',
      };

      final invitation = Invitation.fromJson(json);

      expect(invitation.id, 'inv-1');
      expect(invitation.guestId, 'guest-1');
      expect(invitation.invitationCode, 'INV-2025-ABC123');
      expect(invitation.isUnlocked, false);
    });

    test('copyWith updates fields', () {
      final invitation = Invitation(
        id: 'inv-1',
        guestId: 'guest-1',
        tableId: 'table-1',
        chairId: 'chair-1',
        invitationCode: 'INV-2025-ABC123',
        webUrl: 'https://example.com/guest?token=abc',
        deepLink: 'mariageentienne://guest/abc',
        qrPayload: 'https://example.com/guest?token=abc',
        isUnlocked: false,
      );

      final unlocked = invitation.copyWith(isUnlocked: true);

      expect(unlocked.isUnlocked, true);
      expect(unlocked.id, 'inv-1');
    });
  });

  group('WeddingTable Model', () {
    test('fromJson creates WeddingTable correctly', () {
      final json = {
        'id': 'table-1',
        'label': 'Table Famille',
        'capacity': 8,
        'created_at': '2025-01-15T10:00:00Z',
      };

      final table = WeddingTable.fromJson(json);

      expect(table.id, 'table-1');
      expect(table.label, 'Table Famille');
      expect(table.capacity, 8);
    });

    test('toJson roundtrip preserves data', () {
      final table = WeddingTable(
        id: 'table-1',
        label: 'Table Amis',
        capacity: 6,
      );

      final json = table.toJson();
      final restored = WeddingTable.fromJson(json);

      expect(restored.id, table.id);
      expect(restored.label, table.label);
      expect(restored.capacity, table.capacity);
    });
  });

  group('Chair Model', () {
    test('fromJson creates Chair correctly', () {
      final json = {
        'id': 'chair-1',
        'table_id': 'table-1',
        'chair_number': 3,
        'guest_id': null,
        'created_at': '2025-01-15T10:00:00Z',
      };

      final chair = Chair.fromJson(json);

      expect(chair.id, 'chair-1');
      expect(chair.tableId, 'table-1');
      expect(chair.chairNumber, 3);
      expect(chair.isAssigned, false);
    });
  });

  group('GuestSeat Model', () {
    test('fromJson creates GuestSeat correctly', () {
      final json = {
        'id': 'seat-1',
        'guest_id': 'guest-1',
        'table_id': 'table-1',
        'chair_id': 'chair-1',
        'chair_number': 3,
        'table_label': 'Table Famille',
        'created_at': '2025-01-15T10:00:00Z',
      };

      final seat = GuestSeat.fromJson(json);

      expect(seat.id, 'seat-1');
      expect(seat.guestId, 'guest-1');
      expect(seat.tableId, 'table-1');
      expect(seat.chairId, 'chair-1');
    });
  });

  group('GuestMedia Model', () {
    test('fromJson creates GuestMedia correctly', () {
      final json = {
        'id': 'media-1',
        'guest_id': 'guest-1',
        'media_type': 'audio',
        'storage_path': 'guest-1/recording.m4a',
        'client_duration_seconds': 45,
        'server_duration_seconds': 44.8,
        'client_validated': true,
        'server_validated': true,
        'submitted_at': '2025-01-15T10:00:00Z',
      };

      final media = GuestMedia.fromJson(json);

      expect(media.id, 'media-1');
      expect(media.guestId, 'guest-1');
      expect(media.mediaType, 'audio');
      expect(media.clientDurationSeconds, 45);
      expect(media.isValid, true);
    });

    test('is valid when duration >= 30', () {
      final media = GuestMedia(
        id: 'media-1',
        guestId: 'guest-1',
        mediaType: 'audio',
        storagePath: 'path',
        clientDurationSeconds: 30,
        serverDurationSeconds: 30,
        clientValidated: true,
        serverValidated: true,
      );

      expect(media.isValid, true);
      expect(media.clientDurationSeconds >= 30, true);
    });
  });

  group('Profile Model', () {
    test('fromJson creates Profile correctly', () {
      final json = {
        'id': 'profile-1',
        'event_id': 'event-1',
        'full_name': 'Admin User',
        'phone': '+33612345678',
        'role': 'admin',
        'created_at': '2025-01-15T10:00:00Z',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'profile-1');
      expect(profile.fullName, 'Admin User');
      expect(profile.role, 'admin');
      expect(profile.phone, '+33612345678');
    });

    test('toJson roundtrip preserves data', () {
      final profile = Profile(
        id: 'profile-1',
        eventId: 'event-1',
        fullName: 'Admin User',
        role: 'admin',
      );

      final json = profile.toJson();
      final restored = Profile.fromJson(json);

      expect(restored.id, profile.id);
      expect(restored.fullName, profile.fullName);
      expect(restored.role, profile.role);
    });
  });

  group('EntranceQr Model', () {
    test('fromJson exposes scan and check-in counters', () {
      final qr = EntranceQr.fromJson({
        'id': 'entrance-1',
        'event_id': 'event-1',
        'code': 'entrance-code',
        'url': 'https://example.com/guest-portal?entrance=entrance-code',
        'is_active': true,
        'scan_count': 12,
        'check_in_count': 8,
        'last_scanned_at': '2026-08-26T12:00:00Z',
        'created_at': '2026-08-26T10:00:00Z',
      });

      expect(qr.code, 'entrance-code');
      expect(qr.scanCount, 12);
      expect(qr.checkInCount, 8);
      expect(qr.isActive, true);
    });
  });
}
