import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/services/invitation_export_service.dart';
import '../../data/models/invitation_models.dart';
import '../../data/repositories/wedding_repository.dart';
import 'video_player_factory.dart';

class GuestAccessController extends GetxController {
  GuestAccessController(this.token);

  final String token;
  final WeddingRepository _repository = Get.find<WeddingRepository>();
  final InvitationExportService _exportService =
      Get.find<InvitationExportService>();
  final _audioRecorder = AudioRecorder();
  final _imagePicker = ImagePicker();

  final invitation = Rxn<GuestInvitation>();
  final isLoading = true.obs;
  final isRecordingAudio = false.obs;
  final recordingSeconds = 0.obs;
  final isSubmitting = false.obs;

  Timer? _timer;

  WeddingEvent get event => _repository.event;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadInvitation();
  }

  Future<void> loadInvitation() async {
    isLoading.value = true;
    invitation.value = await _repository.findInvitationByToken(token);
    isLoading.value = false;
  }

  Future<void> startAudioRecording() async {
    if (isRecordingAudio.value) {
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      Get.snackbar(
        'Permission requise',
        'Le microphone est necessaire pour debloquer la carte.',
      );
      return;
    }

    final audioPath = kIsWeb
        ? 'guest-audio-${DateTime.now().millisecondsSinceEpoch}.webm'
        : '${(await getTemporaryDirectory()).path}/guest-audio-${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(const RecordConfig(), path: audioPath);
    recordingSeconds.value = 0;
    isRecordingAudio.value = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      recordingSeconds.value++;
    });
  }

  Future<void> stopAudioRecording() async {
    if (!isRecordingAudio.value) {
      return;
    }

    final path = await _audioRecorder.stop();
    _timer?.cancel();
    isRecordingAudio.value = false;
    await _submitMedia(
      type: MediaType.audio,
      clientDurationSeconds: recordingSeconds.value.toDouble(),
      localReference:
          path ?? 'record://audio/${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> captureVideo() async {
    final file = await _imagePicker.pickVideo(source: ImageSource.camera);
    if (file == null) {
      return;
    }

    final duration = await _resolveVideoDuration(file);
    await _submitMedia(
      type: MediaType.video,
      clientDurationSeconds: duration.inSeconds.toDouble(),
      localReference: file.path,
    );
  }

  Future<void> exportUnlockedCard() async {
    final current = invitation.value;
    if (current == null) {
      return;
    }

    if (!current.isUnlocked) {
      Get.snackbar(
        'Carte verrouillee',
        'Un audio ou une video valide doit etre envoye avant export.',
      );
      return;
    }

    final assets = await _exportService.generateAssets(
      event: event,
      invitation: current,
    );
    await _repository.attachGeneratedAssets(
      invitationId: current.id,
      pngStoragePath: 'invitation-cards/png/${assets.pngFileName}',
      pdfStoragePath: 'invitation-cards/pdf/${assets.pdfFileName}',
    );
    await _exportService.shareAssets(assets);
    Get.snackbar('Carte prete', 'Les versions PNG et PDF ont ete preparees.');
  }

  @override
  void onClose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.onClose();
  }

  Future<void> _submitMedia({
    required MediaType type,
    required double clientDurationSeconds,
    required String localReference,
  }) async {
    if (isSubmitting.value) {
      return;
    }

    isSubmitting.value = true;
    try {
      await _repository.submitGuestMedia(
        token: token,
        type: type,
        clientDurationSeconds: clientDurationSeconds,
        serverDurationSeconds: clientDurationSeconds,
        localReference: localReference,
      );
      await loadInvitation();

      final current = invitation.value;
      if (current != null && current.isUnlocked) {
        Get.snackbar(
          'Validation reussie',
          'Votre carte d\'invitation est maintenant disponible.',
        );
      } else {
        Get.snackbar(
          'Media refuse',
          'La duree doit etre de minimum 30 secondes.',
        );
      }
    } catch (error) {
      Get.snackbar('Erreur', '$error');
    } finally {
      isSubmitting.value = false;
      recordingSeconds.value = 0;
    }
  }

  Future<Duration> _resolveVideoDuration(XFile file) async {
    final controller = createVideoController(file.path);
    await controller.initialize();
    final duration = controller.value.duration;
    await controller.dispose();
    return duration;
  }
}
