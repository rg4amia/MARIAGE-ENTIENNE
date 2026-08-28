import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/invitation_card_generator.dart';
import '../../core/widgets/animated_widgets.dart';
import '../../core/widgets/micro_interactions.dart';
import 'guest_access_controller.dart';
import 'audio_recorder_page.dart';
import 'video_recorder_page.dart';
import 'recorder_factory.dart'
    if (dart.library.html) 'recorder_factory_web.dart';

/// Main guest access page — handles the full public journey via QR token.
class GuestAccessPage extends StatefulWidget {
  const GuestAccessPage({super.key});

  @override
  State<GuestAccessPage> createState() => _GuestAccessPageState();
}

class _GuestAccessPageState extends State<GuestAccessPage>
    with TickerProviderStateMixin {
  late final GuestAccessController controller;
  late final AnimationController _stepCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    controller = Get.find<GuestAccessController>();
    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

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
  void dispose() {
    _stepCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        _stepCtrl.reset();
        _stepCtrl.forward();

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
          child: _buildStep(controller.currentStep.value),
        );
      }),
    );
  }

  Widget _buildStep(GuestAccessStep step) {
    switch (step) {
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
  }

  Widget _buildLoading() {
    return Container(
      key: const ValueKey('loading'),
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleIn(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dark.withValues(alpha: 0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Vérification en cours...',
              style: AppTextStyles.headlineMd.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.dark),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Container(
      key: const ValueKey('notFound'),
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleIn(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.link_off_rounded,
                    size: 48,
                    color: AppColors.error.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Invitation introuvable',
                style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Ce lien d\'invitation n\'est pas valide\nou a expiré.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMdOnVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      key: const ValueKey('error'),
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleIn(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: AppColors.error.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Une erreur est survenue',
                style: AppTextStyles.headlineMd.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMdOnVariant,
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: 'Réessayer',
                onPressed: controller.retry,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerified() {
    final g = controller.guest.value;
    return Container(
      key: const ValueKey('verified'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5C0099), AppColors.primary, AppColors.background],
          stops: [0.0, 0.3, 0.6],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              ScaleIn(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.dark.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.dark.withValues(alpha: 0.15),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.waving_hand_rounded, size: 48, color: AppColors.dark),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Bienvenue,',
                style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.dark.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                g?.fullName ?? '',
                style: AppTextStyles.headlineLg.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(flex: 2),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic)),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dark.withValues(alpha: 0.06),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '📸',
                        style: const TextStyle(fontSize: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Enregistrez votre message',
                        style: AppTextStyles.titleLg.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pour débloquer votre carte d\'invitation, enregistrez un message audio ou vidéo d\'au moins 30 secondes pour le couple.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GradientButton(
                        label: 'Commencer',
                        onPressed: controller.goToMediaChoice,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaChoice() {
    return Container(
      key: const ValueKey('mediaChoice'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5C0099), AppColors.primary, AppColors.background],
          stops: [0.0, 0.3, 0.6],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              ScaleIn(
                child: const Icon(
                  Icons.mic_rounded,
                  size: 48,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choisissez votre format',
                style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enregistrez un message pour le couple',
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.dark.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(flex: 1),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic)),
                child: _MediaOptionCard(
                  icon: Icons.mic_rounded,
                  title: 'Message Audio',
                  subtitle: 'Enregistrez un message vocal',
                  color: AppColors.dark,
                  onTap: controller.startAudioRecording,
                ),
              ),
              const SizedBox(height: 16),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic)),
                child: _MediaOptionCard(
                  icon: Icons.videocam_rounded,
                  title: 'Message Vidéo',
                  subtitle: 'Enregistrez une courte vidéo',
                  color: AppColors.primary,
                  onTap: controller.startVideoRecording,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingPage({required bool isAudio}) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _openRecorder(isAudio));
    return _buildProcessing();
  }

  Future<void> _openRecorder(bool isAudio) async {
    Widget recorderPage;
    if (kIsWeb) {
      recorderPage = isAudio
          ? buildWebAudioRecorderPage(minDurationSeconds: 30)
          : buildWebVideoRecorderPage(minDurationSeconds: 30);
    } else {
      recorderPage = isAudio
          ? const AudioRecorderPage(minDurationSeconds: 30)
          : const VideoRecorderPage(minDurationSeconds: 30);
    }

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => recorderPage),
    );

    if (result != null && result.isNotEmpty) {
      controller.setRecordedFile(result, durationSeconds: controller.recordingDuration.value);
      controller.submitMedia(isAudio: isAudio, durationSeconds: controller.recordingDuration.value);
    } else {
      controller.currentStep.value = GuestAccessStep.mediaChoice;
    }
  }

  Widget _buildProcessing() {
    return Container(
      key: const ValueKey('processing'),
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleIn(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Traitement en cours...',
              style: AppTextStyles.headlineMd,
            ),
            const SizedBox(height: 8),
            Text(
              'Nous traitons votre enregistrement',
              style: AppTextStyles.bodyMdOnVariant,
            ),
          ],
        ),
      ),
    );
  }

  final GlobalKey _cardKey = GlobalKey();

  Widget _buildCardUnlocked() {
    final g = controller.guest.value;
    return Container(
      key: const ValueKey('unlocked'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark, AppColors.background],
          stops: [0.0, 0.2, 0.5],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              ScaleIn(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.dark.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.dark.withValues(alpha: 0.2), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, size: 44, color: AppColors.dark),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Carte débloquée !',
                style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Merci pour votre message, ${g?.fullName ?? ''} ! 🎉',
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.dark.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 28),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic)),
                child: InvitationCardWidget(
                  key: _cardKey,
                  guestName: g?.fullName ?? 'Invité',
                  tableName: controller.guestSeat.value?.tableId ?? 'Non assigné',
                  seatNumber: controller.guestSeat.value?.chairId ?? '-',
                  qrToken: g?.qrToken,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadCard(g?.fullName ?? 'invite'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dark,
                        side: BorderSide(color: AppColors.dark.withValues(alpha: 0.3), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text('Télécharger', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareCard(g?.fullName ?? 'invite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: const Text('Partager', style: TextStyle(fontWeight: FontWeight.w600)),
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
      Get.snackbar('Succès', 'Carte sauvegardée', snackPosition: SnackPosition.BOTTOM);
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

// ── Media Option Card ──
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
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
              child: Icon(icon, color: color, size: 26),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.onSurfaceVariant,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
