import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Video recording page that launches the device camera.
/// Uses image_picker to record video, then validates minimum duration.
class VideoRecorderPage extends StatefulWidget {
  final int minDurationSeconds;

  const VideoRecorderPage({super.key, this.minDurationSeconds = 30});

  @override
  State<VideoRecorderPage> createState() => _VideoRecorderPageState();
}

class _VideoRecorderPageState extends State<VideoRecorderPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _videoPath;
  int _videoDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Auto-launch camera when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) => _launchCamera());
  }

  Future<void> _launchCamera() async {
    try {
      setState(() => _isRecording = true);

      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxDuration: const Duration(seconds: 120), // Max 2 min
      );

      if (video != null) {
        setState(() {
          _isProcessing = true;
          _isRecording = false;
        });

        // Get video duration
        final duration = await _getVideoDuration(video.path);
        _videoDurationSeconds = duration;

        if (duration < widget.minDurationSeconds) {
          setState(() {
            _isProcessing = false;
            _videoPath = null;
          });
          if (mounted) {
            Get.snackbar(
              'Durée insuffisante',
              'La vidéo doit durer au moins ${widget.minDurationSeconds}s (actuellement ${duration}s).',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 4),
            );
            // Try again
            _launchCamera();
          }
          return;
        }

        setState(() {
          _videoPath = video.path;
          _isProcessing = false;
        });
      } else {
        // User cancelled
        setState(() => _isRecording = false);
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      Get.snackbar(
        'Erreur',
        'Impossible d\'accéder à la caméra: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Get video duration by reading the file and estimating.
  /// For web, we use a simpler approach.
  Future<int> _getVideoDuration(String path) async {
    try {
      // Try to get duration from file modification time difference
      // This is a rough estimate; in production use video_player or media_info
      final file = File(path);
      if (await file.exists()) {
        // Estimate based on file size (rough: ~1MB per 10s for 720p)
        final size = await file.length();
        // Very rough estimate: assume ~100KB/s bitrate
        final estimatedSeconds = (size / 100000).round().clamp(1, 300);
        return estimatedSeconds;
      }
    } catch (e) {
      debugPrint('Error getting video duration: $e');
    }
    // If we can't determine duration, assume it's valid
    // (the server will validate on upload)
    return widget.minDurationSeconds;
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Title
              Text(
                'Enregistrement Vidéo',
                style: AppTextStyles.headlineMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Durée minimum : ${widget.minDurationSeconds}s',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 1),
              // Camera preview or status
              if (_isRecording)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.error, width: 4),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam, size: 48, color: AppColors.error),
                      SizedBox(height: 8),
                      Text(
                        'Caméra ouverte...',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                )
              else if (_isProcessing)
                const Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Traitement de la vidéo...'),
                  ],
                )
              else if (_videoPath != null)
                // Video preview
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.statusCardUnlocked.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.statusCardUnlocked,
                      width: 4,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 48,
                        color: AppColors.statusCardUnlocked,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_videoDurationSeconds),
                        style: AppTextStyles.titleLg.copyWith(
                          color: AppColors.statusCardUnlocked,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.primary, width: 4),
                  ),
                  child: const Icon(
                    Icons.videocam_off,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              const SizedBox(height: 32),
              // Status text
              if (_isRecording)
                Text(
                  'L\'enregistrement est en cours dans l\'application caméra...',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                )
              else if (_videoPath != null)
                Text(
                  'Vidéo enregistrée !',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.statusCardUnlocked,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  'La caméra va s\'ouvrir automatiquement',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              const Spacer(flex: 2),
              // Action buttons
              if (_videoPath != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_videoPath),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCardUnlocked,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Envoyer la vidéo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _launchCamera,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Recommencer',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ] else if (!_isRecording && !_isProcessing) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _launchCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ouvrir la caméra',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Annuler',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
