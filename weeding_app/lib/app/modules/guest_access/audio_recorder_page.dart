import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Real audio recording page using flutter_sound package.
/// Records audio from microphone with minimum 30s duration.
class AudioRecorderPage extends StatefulWidget {
  final int minDurationSeconds;

  const AudioRecorderPage({super.key, this.minDurationSeconds = 30});

  @override
  State<AudioRecorderPage> createState() => _AudioRecorderPageState();
}

class _AudioRecorderPageState extends State<AudioRecorderPage>
    with SingleTickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
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
    await _recorder.openRecorder();
    setState(() => _isRecorderInitialized = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.closeRecorder();
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
    if (!_isRecorderInitialized) {
      Get.snackbar(
        'Erreur',
        'Enregistreur non initialisé',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
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

    final path = await _recorder.stopRecorder();

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    if (path != null && path.isNotEmpty && mounted) {
      Navigator.of(context).pop(path);
    }
  }

  void _togglePause() {
    if (_isPaused) {
      _recorder.resumeRecorder();
      setState(() => _isPaused = false);
      _pulseController?.repeat(reverse: true);
    } else {
      _recorder.pauseRecorder();
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
          icon: Icon(Icons.close, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
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
                            : AppColors.primary,
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
                        color: _isRecording ? AppColors.error : AppColors.dark,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
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
                    _hasMinimumDuration
                        ? '✓ Minimum atteint'
                        : 'Minimum: ${widget.minDurationSeconds}s',
                    style: AppTextStyles.labelMd.copyWith(
                      color: _hasMinimumDuration
                          ? AppColors.statusCardUnlocked
                          : AppColors.onSurfaceVariant,
                      fontWeight: _hasMinimumDuration
                          ? FontWeight.w600
                          : FontWeight.normal,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? AppColors.error : AppColors.dark,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (_isRecording
                                        ? AppColors.error
                                        : AppColors.primary)
                                    .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 36,
                        color: _isRecording ? Colors.white : AppColors.dark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
