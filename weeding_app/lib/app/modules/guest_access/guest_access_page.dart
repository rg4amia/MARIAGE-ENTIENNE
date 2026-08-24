import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/invitation_card_generator.dart';
import 'guest_access_controller.dart';
import 'audio_recorder_page.dart';
import 'video_recorder_page.dart';
import 'web_audio_recorder.dart';
import 'web_video_recorder.dart';

/// Main guest access page — handles the full public journey via QR token.
/// Route: /guest/:token
/// No auth required.
class GuestAccessPage extends StatefulWidget {
  const GuestAccessPage({super.key});

  @override
  State<GuestAccessPage> createState() => _GuestAccessPageState();
}

class _GuestAccessPageState extends State<GuestAccessPage> {
  late final GuestAccessController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<GuestAccessController>();
    // Extract token from route parameter
    final token = Get.parameters['token'] ?? '';
    if (token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.verifyGuest(token);
      });
    } else {
      controller.currentStep.value = GuestAccessStep.notFound;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        switch (controller.currentStep.value) {
          case GuestAccessStep.loading:
            return _buildLoading();
          case GuestAccessStep.notFound:
            return _buildNotFound();
          case GuestAccessStep.error:
            return _buildError();
          case GuestAccessStep.verified:
            return _buildVerified();
          case GuestAccessStep.mediaChoice:
            return _buildMediaChoice();
          case GuestAccessStep.recordingAudio:
            return _buildRecordingPage(isAudio: true);
          case GuestAccessStep.recordingVideo:
            return _buildRecordingPage(isAudio: false);
          case GuestAccessStep.processing:
            return _buildProcessing();
          case GuestAccessStep.cardUnlocked:
            return _buildCardUnlocked();
        }
      }),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text('Vérification en cours...'),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              'Invitation introuvable',
              style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ce lien d\'invitation n\'est pas valide ou a expiré.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              'Une erreur est survenue',
              style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerified() {
    final g = controller.guest.value;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.background],
          stops: [0.0, 0.4],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Welcome icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bienvenue,',
                style: AppTextStyles.headlineMd.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                g?.fullName ?? '',
                style: AppTextStyles.headlineLg.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(flex: 1),
              // Info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Enregistrez votre message',
                      style: AppTextStyles.titleLg.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pour débloquer votre carte d\'invitation, '
                      'enregistrez un message audio ou vidéo d\'au moins 30 secondes.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.goToMediaChoice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Commencer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaChoice() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.background],
          stops: [0.0, 0.4],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Text(
                'Choisissez votre format',
                style: AppTextStyles.headlineMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enregistrez un message pour le couple',
                style: AppTextStyles.bodyLg.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(flex: 1),
              // Audio option
              _MediaOptionCard(
                icon: Icons.mic,
                title: 'Message Audio',
                subtitle: 'Enregistrez un message vocal',
                color: AppColors.secondary,
                onTap: controller.startAudioRecording,
              ),
              const SizedBox(height: 16),
              // Video option
              _MediaOptionCard(
                icon: Icons.videocam,
                title: 'Message Vidéo',
                subtitle: 'Enregistrez une vidéo',
                color: AppColors.tertiary,
                onTap: controller.startVideoRecording,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingPage({required bool isAudio}) {
    // Navigate to real recorder and handle result
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openRecorder(isAudio);
    });
    return _buildProcessing();
  }

  Future<void> _openRecorder(bool isAudio) async {
    Widget recorderPage;

    if (kIsWeb) {
      // Use web-specific recorders with MediaRecorder API
      recorderPage = isAudio
          ? const WebAudioRecorderPage(minDurationSeconds: 30)
          : const WebVideoRecorderPage(minDurationSeconds: 30);
    } else {
      // Use native mobile recorders
      recorderPage = isAudio
          ? const AudioRecorderPage(minDurationSeconds: 30)
          : const VideoRecorderPage(minDurationSeconds: 30);
    }

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => recorderPage),
    );

    if (result != null && result.isNotEmpty) {
      // File recorded successfully — get duration and submit
      controller.setRecordedFile(result, durationSeconds: controller.recordingDuration.value);
      controller.submitMedia(
        isAudio: isAudio,
        durationSeconds: controller.recordingDuration.value,
      );
    } else {
      // User cancelled — go back to media choice
      controller.currentStep.value = GuestAccessStep.mediaChoice;
    }
  }

  Widget _buildProcessing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'Traitement en cours...',
            style: AppTextStyles.headlineMd.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nous traitons votre enregistrement',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // GlobalKey for capturing the card as PNG
  final GlobalKey _cardKey = GlobalKey();

  Widget _buildCardUnlocked() {
    final g = controller.guest.value;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.background],
          stops: [0.0, 0.3],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.statusCardUnlocked,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Carte débloquée !',
                style: AppTextStyles.headlineMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Merci pour votre message, ${g?.fullName ?? ''} !',
                style: AppTextStyles.bodyLg.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 24),
              // Invitation card (capturable)
              InvitationCardWidget(
                key: _cardKey,
                guestName: g?.fullName ?? 'Invité',
                tableName: controller.guestSeat.value?.tableId ?? 'Non assigné',
                seatNumber: controller.guestSeat.value?.chairId ?? '-',
                qrToken: g?.qrToken,
              ),
              const SizedBox(height: 20),
              // Download & Share buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadCard(g?.fullName ?? 'invite'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.download),
                      label: const Text('Télécharger'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareCard(g?.fullName ?? 'invite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.share),
                      label: const Text('Partager'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadCard(String guestName) async {
    final imageBytes = await InvitationCardGenerator.captureCard(_cardKey);
    if (imageBytes == null) {
      Get.snackbar('Erreur', 'Impossible de capturer la carte', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final path = await InvitationCardGenerator.saveToFile(
      imageBytes,
      'invitation_${guestName.replaceAll(' ', '_')}.png',
    );
    if (path != null) {
      Get.snackbar('Succès', 'Carte sauvegardée dans $path', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _shareCard(String guestName) async {
    final imageBytes = await InvitationCardGenerator.captureCard(_cardKey);
    if (imageBytes == null) {
      Get.snackbar('Erreur', 'Impossible de capturer la carte', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    await InvitationCardGenerator.shareCard(imageBytes, guestName);
  }
}

/// Media option card widget
class _MediaOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MediaOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleLg.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppColors.onSurfaceVariant, size: 16),
          ],
        ),
      ),
    );
  }
}



