import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Real audio recording page using the record package.
/// Records audio from microphone with minimum 30s duration.
class AudioRecorderPage extends StatefulWidget {
  final int minDurationSeconds;

  const AudioRecorderPage({
    super.key,
    this.minDurationSeconds = 30,
  });

  @override
  State<AudioRecorderPage> createState() => _AudioRecorderPageState();
}

class _AudioRecorderPageState extends State<AudioRecorderPage>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  AnimationController? _pulseController;
  String? _outputPath;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    if (await _recorder.hasPermission()) {
      // Ready to record
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  bool get _hasMinimumDuration => _elapsedSeconds >= widget.minDurationSeconds;

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      Get.snackbar(
        'Permission requise',
        'L\'accès au microphone est nécessaire pour enregistrer.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _elapsedSeconds = 0;
        _outputPath = filePath;
      });

      _pulseController?.repeat(reverse: true);

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isPaused) {
          setState(() => _elapsedSeconds++);
        }
      });
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer l\'enregistrement: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController?.stop();

    final path = await _recorder.stop();

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    if (path != null && path.isNotEmpty && mounted) {
      // Return the file path to the previous page
      Navigator.of(context).pop(path);
    }
  }

  void _togglePause() {
    if (_isPaused) {
      _recorder.resume();
      setState(() => _isPaused = false);
      _pulseController?.repeat(reverse: true);
    } else {
      _recorder.pause();
      setState(() => _isPaused = true);
      _pulseController?.stop();
    }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              // Title
              Text(
                'Enregistrement Audio',
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
              // Waveform / Pulse indicator
              AnimatedBuilder(
                animation: _pulseController!,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController!.value * 0.15);
                  return Transform.scale(
                    scale: _isRecording ? scale : 1.0,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? AppColors.error.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: _isRecording
                              ? AppColors.error
                              : AppColors.primary,
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        _isRecording
                            ? (_isPaused ? Icons.pause : Icons.mic)
                            : Icons.mic_none,
                        size: 56,
                        color: _isRecording ? AppColors.error : AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Timer
              Text(
                _formatDuration(_elapsedSeconds),
                style: AppTextStyles.displayMd.copyWith(
                  color: _hasMinimumDuration
                      ? AppColors.statusCardUnlocked
                      : AppColors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Status text
              if (_isRecording)
                Text(
                  _isPaused ? 'En pause' : 'Enregistrement...',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: _isPaused
                        ? AppColors.onSurfaceVariant
                        : AppColors.error,
                  ),
                )
              else
                Text(
                  'Appuyez pour commencer',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_elapsedSeconds / 60).clamp(0.0, 1.0),
                  backgroundColor: AppColors.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _hasMinimumDuration
                        ? AppColors.statusCardUnlocked
                        : AppColors.primary,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              // Duration indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0:00',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _hasMinimumDuration ? '✓ Minimum atteint' : 'Minimum: ${widget.minDurationSeconds}s',
                    style: AppTextStyles.labelMd.copyWith(
                      color: _hasMinimumDuration
                          ? AppColors.statusCardUnlocked
                          : AppColors.onSurfaceVariant,
                      fontWeight: _hasMinimumDuration ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    '1:00',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pause/Resume button
                  if (_isRecording)
                    GestureDetector(
                      onTap: _togglePause,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceContainer,
                        ),
                        child: Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          size: 28,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  if (_isRecording) const SizedBox(width: 24),
                  // Main record/stop button
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? AppColors.error : AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording ? AppColors.error : AppColors.primary)
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Done button (only show if recording is done and meets minimum)
              if (!_isRecording && _outputPath != null && _hasMinimumDuration)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_outputPath),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCardUnlocked,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Envoyer l\'enregistrement',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
