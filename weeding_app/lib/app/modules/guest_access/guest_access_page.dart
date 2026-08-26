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
        // Animate on step change
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

  // ── Loading ──
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
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Not Found ──
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

  // ── Error ──
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

  // ── Verified / Welcome ──
  Widget _buildVerified() {
    final g = controller.guest.value;
    return Container(
      key: const ValueKey('verified'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, Color(0xFFE85D2A), AppColors.background],
          stops: [0.0, 0.3, 0.6],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Welcome circle
              ScaleIn(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.waving_hand_rounded, size: 48, color: Colors.white),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Bienvenue,',
                style: AppTextStyles.headlineMd.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
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
              const Spacer(flex: 2),
              // Info card
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
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

  // ── Media Choice ──
  Widget _buildMediaChoice() {
    return Container(
      key: const ValueKey('mediaChoice'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, Color(0xFFE85D2A), AppColors.background],
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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
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
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(flex: 1),
              // Audio option
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic)),
                child: _MediaOptionCard(
                  icon: Icons.mic_rounded,
                  title: 'Message Audio',
                  subtitle: 'Enregistrez un message vocal',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7A3D), Color(0xFFE85D2A)],
                  ),
                  onTap: controller.startAudioRecording,
                ),
              ),
              const SizedBox(height: 16),
              // Video option
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic)),
                child: _MediaOptionCard(
                  icon: Icons.videocam_rounded,
                  title: 'Message Vidéo',
                  subtitle: 'Enregistrez une courte vidéo',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C4236), Color(0xFFB85A4E)],
                  ),
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

  // ── Recording (navigates to real recorder) ──
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

  // ── Processing ──
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
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                  ),
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

  // ── Card Unlocked ──
  final GlobalKey _cardKey = GlobalKey();

  Widget _buildCardUnlocked() {
    final g = controller.guest.value;
    return Container(
      key: const ValueKey('unlocked'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4CAF50), Color(0xFF388E3C), AppColors.background],
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
              // Success animation
              ScaleIn(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, size: 44, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Carte débloquée !',
                style: AppTextStyles.headlineMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Merci pour votre message, ${g?.fullName ?? ''} ! 🎉',
                style: AppTextStyles.bodyLg.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 28),
              // Invitation card
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
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadCard(g?.fullName ?? 'invite'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF388E3C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
  final Gradient gradient;
  final VoidCallback onTap;

  const _MediaOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
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
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
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
                color: AppColors.surfaceContainerLow,
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
