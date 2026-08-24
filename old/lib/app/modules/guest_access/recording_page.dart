import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/wedding_bottom_nav.dart';
import '../../core/widgets/wedding_cards.dart';
import '../../core/widgets/wedding_top_bar.dart';
import 'guest_access_controller.dart';

/// Page "Enregistrement Media" reproduisant le design Stitch :
/// canvas central avec viewport video, toggle Video/Audio, bouton
/// d'enregistrement avec halo pulsant, barre de progression 30s.
class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key, required this.token});

  final String token;

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage>
    with SingleTickerProviderStateMixin {
  late final GuestAccessController controller;
  late final AnimationController _pulse;
  bool _videoMode = true;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      GuestAccessController(widget.token),
      tag: widget.token,
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const WeddingTopBar(),
      bottomNavigationBar: WeddingBottomNav(
        current: WeddingNavItem.invitations,
        onTap: (item) {
          if (item == WeddingNavItem.invitations) return;
          Get.back();
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            const EyebrowLabel("L'heritage digital"),
            const SizedBox(height: 12),
            Text(
              'Enregistrez\nvotre message',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerif(
                color: AppColors.primary,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                height: 1.05,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 48,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            _RecorderCanvas(
              videoMode: _videoMode,
              onModeChanged: (value) => setState(() => _videoMode = value),
              controller: controller,
              pulse: _pulse,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _RecorderCanvas extends StatelessWidget {
  const _RecorderCanvas({
    required this.videoMode,
    required this.onModeChanged,
    required this.controller,
    required this.pulse,
  });

  final bool videoMode;
  final ValueChanged<bool> onModeChanged;
  final GuestAccessController controller;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        boxShadow: kWeddingGlow,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          _ModeToggle(videoMode: videoMode, onChanged: onModeChanged),
          const SizedBox(height: 28),
          _Viewport(
            videoMode: videoMode,
            controller: controller,
            pulse: pulse,
          ),
          const SizedBox(height: 28),
          Obx(() {
            final seconds = controller.recordingSeconds.value;
            return Column(
              children: [
                Text(
                  'Votre message doit durer au moins 30 secondes\npour debloquer l\'invitation',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (seconds / 30).clamp(0, 1),
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.secondaryContainer,
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Envoyer le message',
            icon: Icons.send_rounded,
            expand: true,
            onPressed: () async {
              if (controller.isRecordingAudio.value) {
                await controller.stopAudioRecording();
              }
              Get.back();
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              if (controller.isRecordingAudio.value) {
                controller.stopAudioRecording();
              }
            },
            child: Text(
              "Recommencer l'enregistrement".toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 10,
                letterSpacing: 1.4,
                color: AppColors.outline,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.videoMode, required this.onChanged});

  final bool videoMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn('Video', videoMode, () => onChanged(true)),
          _toggleBtn('Audio', !videoMode, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.outline,
          ),
        ),
      ),
    );
  }
}

class _Viewport extends StatelessWidget {
  const _Viewport({
    required this.videoMode,
    required this.controller,
    required this.pulse,
  });

  final bool videoMode;
  final GuestAccessController controller;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1010), Color(0xFF1B1C17)],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 14,
              child: Obx(() {
                final s = controller.recordingSeconds.value;
                final mm = (s ~/ 60).toString().padLeft(2, '0');
                final ss = (s % 60).toString().padLeft(2, '0');
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    '$mm:$ss / 00:30',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 14,
                    ),
                  ),
                );
              }),
            ),
            // Halo pulsant
            Obx(() {
              if (!controller.isRecordingAudio.value) {
                return const SizedBox.shrink();
              }
              return AnimatedBuilder(
                animation: pulse,
                builder: (_, _) {
                  final t = pulse.value;
                  return Container(
                    width: 100 + 30 * t,
                    height: 100 + 30 * t,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.secondaryContainer
                            .withValues(alpha: (1 - t).clamp(0, 1)),
                        width: 2,
                      ),
                    ),
                  );
                },
              );
            }),
            // Bouton record
            GestureDetector(
              onTap: () async {
                if (videoMode) {
                  if (kIsWeb) {
                    Get.snackbar(
                      'Mode video',
                      'La capture video web utilise le picker du navigateur.',
                    );
                  }
                  await controller.captureVideo();
                  return;
                }
                if (controller.isRecordingAudio.value) {
                  await controller.stopAudioRecording();
                } else {
                  await controller.startAudioRecording();
                }
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: kEditorialGradient,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55570013),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Obx(() {
                  final isRec = controller.isRecordingAudio.value;
                  return Icon(
                    videoMode
                        ? Icons.videocam
                        : (isRec ? Icons.stop_rounded : Icons.mic),
                    color: Colors.white,
                    size: 32,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
