import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/guest.dart';
import '../../data/models/invitation.dart';
import '../../data/models/guest_seat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/guest_repository.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../data/repositories/media_repository.dart';

enum GuestAccessStep {
  loading,
  notFound,
  verified,
  mediaChoice,
  recordingAudio,
  recordingVideo,
  processing,
  cardUnlocked,
  error,
}

class GuestAccessController extends GetxController {
  final GuestRepository _guestRepo = GuestRepository();
  final InvitationRepository _invitationRepo = InvitationRepository();
  final MediaRepository _mediaRepo = MediaRepository();
  final _client = Supabase.instance.client;

  final Rx<GuestAccessStep> currentStep = GuestAccessStep.loading.obs;
  final Rx<Guest?> guest = Rx<Guest?>(null);
  final Rx<Invitation?> invitation = Rx<Invitation?>(null);
  final Rx<GuestSeat?> guestSeat = Rx<GuestSeat?>(null);
  final RxString errorMessage = ''.obs;
  final RxBool isProcessing = false.obs;

  // Recording state
  final RxInt recordingDuration = 0.obs;
  final RxBool isRecording = false.obs;
  Timer? _recordingTimer;
  String? _recordedFilePath;
  final int minRecordingDuration = 30; // seconds

  @override
  void onClose() {
    _recordingTimer?.cancel();
    super.onClose();
  }

  /// Verify guest by QR token or short code (called from URL path parameter)
  Future<void> verifyGuest(String identifier) async {
    currentStep.value = GuestAccessStep.loading;

    try {
      // First try to find by short code in guest_links table
      Guest? foundGuest;

      // Check if it looks like a short code (8 chars, alphanumeric)
      final isShortCode =
          identifier.length <= 8 &&
          RegExp(r'^[a-zA-Z0-9]+$').hasMatch(identifier);

      if (isShortCode) {
        // Try to find via guest_links table
        final linkResponse = await _client
            .from('guest_links')
            .select('guest_token, is_active')
            .eq('short_code', identifier)
            .maybeSingle();

        if (linkResponse != null && linkResponse['is_active'] == true) {
          final guestToken = linkResponse['guest_token'] as String;
          foundGuest = await _guestRepo.getGuestByToken(guestToken);
        }
      }

      // Fallback: direct token lookup
      foundGuest ??= await _guestRepo.getGuestByToken(identifier);

      if (foundGuest == null) {
        currentStep.value = GuestAccessStep.notFound;
        return;
      }

      guest.value = foundGuest;

      // Check if guest already unlocked their card
      if (foundGuest.status == 'card_unlocked') {
        // Load invitation for card display
        await _loadInvitation(foundGuest.id);
        currentStep.value = GuestAccessStep.cardUnlocked;
        return;
      }

      // Check if media already uploaded
      if (foundGuest.status == 'media_uploaded') {
        currentStep.value = GuestAccessStep.processing;
        return;
      }

      // Guest verified — show media choice
      currentStep.value = GuestAccessStep.verified;
    } catch (e) {
      debugPrint('Error verifying guest: $e');
      errorMessage.value =
          'Erreur lors de la vérification. Veuillez réessayer.';
      currentStep.value = GuestAccessStep.error;
    }
  }

  /// Proceed to media choice screen
  void goToMediaChoice() {
    currentStep.value = GuestAccessStep.mediaChoice;
  }

  /// Start audio recording flow
  void startAudioRecording() {
    recordingDuration.value = 0;
    isRecording.value = false;
    _recordedFilePath = null;
    currentStep.value = GuestAccessStep.recordingAudio;
  }

  /// Start video recording flow
  void startVideoRecording() {
    recordingDuration.value = 0;
    isRecording.value = false;
    _recordedFilePath = null;
    currentStep.value = GuestAccessStep.recordingVideo;
  }

  /// Called by the recording page when recording starts
  void onRecordingStarted() {
    isRecording.value = true;
    recordingDuration.value = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      recordingDuration.value++;
    });
  }

  /// Called by the recording page when recording stops
  void onRecordingStopped(String filePath) {
    _recordingTimer?.cancel();
    isRecording.value = false;
    _recordedFilePath = filePath;
  }

  /// Set the recorded file path from external recorder page
  void setRecordedFile(String filePath, {int? durationSeconds}) {
    _recordedFilePath = filePath;
    if (durationSeconds != null) {
      recordingDuration.value = durationSeconds;
    }
  }

  /// Check if minimum recording duration is met
  bool get hasMinimumDuration =>
      recordingDuration.value >= minRecordingDuration;

  /// Upload the recorded media and process
  Future<void> submitMedia({
    required bool isAudio,
    int? durationSeconds,
  }) async {
    if (_recordedFilePath == null || guest.value == null) return;

    final effectiveDuration = durationSeconds ?? recordingDuration.value;

    if (effectiveDuration < minRecordingDuration) {
      Get.snackbar(
        'Durée insuffisante',
        'L\'enregistrement doit durer au moins $minRecordingDuration secondes.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isProcessing.value = true;
    currentStep.value = GuestAccessStep.processing;

    try {
      final file = File(_recordedFilePath!);
      if (!await file.exists()) {
        throw Exception('Fichier d\'enregistrement introuvable');
      }

      final mediaType = isAudio ? 'audio' : 'video';
      final fileBytes = await file.readAsBytes();

      // Upload to storage
      final storagePath = await _mediaRepo.uploadMediaToStorage(
        guestId: guest.value!.id,
        mediaType: mediaType,
        filePath: _recordedFilePath!,
        fileBytes: fileBytes,
      );

      // Submit media record (handles validation + card unlock)
      await _mediaRepo.submitMedia(
        guestId: guest.value!.id,
        mediaType: mediaType,
        storagePath: storagePath,
        durationSeconds: effectiveDuration,
      );

      // Reload guest data
      guest.value = await _guestRepo.getGuestById(guest.value!.id);

      // Load invitation for card display
      await _loadInvitation(guest.value!.id);

      // Card is now unlocked
      currentStep.value = GuestAccessStep.cardUnlocked;
    } catch (e) {
      debugPrint('Error uploading media: $e');
      errorMessage.value = 'Erreur lors de l\'envoi. Veuillez réessayer.';
      currentStep.value = GuestAccessStep.error;
    } finally {
      isProcessing.value = false;
    }
  }

  /// Retry after error
  void retry() {
    errorMessage.value = '';
    if (guest.value != null) {
      verifyGuest(guest.value!.qrToken);
    }
  }

  Future<void> _loadInvitation(String guestId) async {
    try {
      final inv = await _invitationRepo.getInvitationByGuestId(guestId);
      invitation.value = inv;
      guestSeat.value = await _guestRepo.getGuestSeat(guestId);
    } catch (e) {
      debugPrint('Error loading invitation: $e');
    }
  }
}
