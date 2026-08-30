// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Web-only audio recorder using the HTML5 MediaRecorder API.
/// Records audio from microphone with minimum 30s duration.
class WebAudioRecorderPage extends StatefulWidget {
  final int minDurationSeconds;

  const WebAudioRecorderPage({super.key, this.minDurationSeconds = 30});

  @override
  State<WebAudioRecorderPage> createState() => _WebAudioRecorderPageState();
}

class _WebAudioRecorderPageState extends State<WebAudioRecorderPage>
    with SingleTickerProviderStateMixin {
  html.MediaRecorder? _recorder;
  html.MediaStream? _stream;
  final List<html.Blob> _chunks = [];

  bool _isRecording = false;
  bool _isPaused = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stream?.getTracks().forEach((t) => t.stop());
    _pulseController?.dispose();
    super.dispose();
  }

  bool get _hasMinimumDuration => _elapsedSeconds >= widget.minDurationSeconds;

  Future<void> _startRecording() async {
    try {
      _chunks.clear();

      // Request microphone access
      _stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'audio': true,
        'video': false,
      });

      _recorder = html.MediaRecorder(_stream!, {'mimeType': 'audio/webm'});
      _recorder!.addEventListener('dataavailable', (event) {
        final blobEvent = event as html.BlobEvent;
        if (blobEvent.data != null && blobEvent.data!.size > 0) {
          _chunks.add(blobEvent.data!);
        }
      });

      _recorder!.start(1000); // Collect data every 1 second

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _elapsedSeconds = 0;
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
        'Impossible d\'accéder au microphone: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController?.stop();

    if (_recorder?.state == 'recording') {
      _recorder!.stop();
    }

    // Wait a bit for data to arrive
    await Future.delayed(const Duration(milliseconds: 500));

    // Stop all tracks
    _stream?.getTracks().forEach((t) => t.stop());

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    if (_chunks.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Aucune donnée enregistrée',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Create blob and upload
    final blob = html.Blob(_chunks, 'audio/webm');
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);

    await reader.onLoad.first;

    final bytes = Uint8List.fromList(reader.result as List<int>);

    // Upload to Supabase
    try {
      final client = Supabase.instance.client;
      final guestId = Get.parameters['guestId'] ?? '';
      if (guestId.isEmpty) {
        throw Exception('Guest ID not found');
      }

      final path =
          '$guestId/audio_${DateTime.now().millisecondsSinceEpoch}.webm';
      await client.storage
          .from('guest-audios')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Return path
      if (mounted) {
        Navigator.of(context).pop(path);
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur upload: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _togglePause() {
    if (_isPaused) {
      _recorder?.resume();
      setState(() => _isPaused = false);
      _pulseController?.repeat(reverse: true);
    } else {
      _recorder?.pause();
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
              // Pulse indicator
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
                        color: _isRecording
                            ? AppColors.error
                            : AppColors.primary,
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
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? AppColors.error
                            : AppColors.primary,
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _isRecording
                    ? 'Appuyez pour arrêter'
                    : 'Appuyez pour commencer',
                style: AppTextStyles.bodyMd.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
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
