// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Web-only video recorder using the HTML5 MediaRecorder API.
/// Records video from camera with minimum 30s duration.
class WebVideoRecorderPage extends StatefulWidget {
  final int minDurationSeconds;

  const WebVideoRecorderPage({super.key, this.minDurationSeconds = 30});

  @override
  State<WebVideoRecorderPage> createState() => _WebVideoRecorderPageState();
}

class _WebVideoRecorderPageState extends State<WebVideoRecorderPage> {
  html.MediaRecorder? _recorder;
  html.MediaStream? _stream;
  html.VideoElement? _videoElement;
  final List<html.Blob> _chunks = [];

  bool _isRecording = false;
  bool _isPaused = false;
  bool _cameraReady = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stream?.getTracks().forEach((t) => t.stop());
    _videoElement?.srcObject = null;
    _videoElement?.remove();
    super.dispose();
  }

  bool get _hasMinimumDuration => _elapsedSeconds >= widget.minDurationSeconds;

  Future<void> _initCamera() async {
    try {
      _stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'audio': true,
        'video': true,
      });

      _videoElement = html.VideoElement()
        ..srcObject = _stream
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      // Attach to DOM
      final videoContainer = html.document.getElementById('video-container');
      videoContainer?.children.clear();
      videoContainer?.append(_videoElement!);

      setState(() => _cameraReady = true);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'accéder à la caméra: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _startRecording() async {
    if (!_cameraReady || _stream == null) return;

    try {
      _chunks.clear();

      _recorder = html.MediaRecorder(_stream!, {'mimeType': 'video/webm'});
      _recorder!.addEventListener('dataavailable', (event) {
        final blobEvent = event as html.BlobEvent;
        if (blobEvent.data != null && blobEvent.data!.size > 0) {
          _chunks.add(blobEvent.data!);
        }
      });

      _recorder!.start(1000);

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _elapsedSeconds = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isPaused) {
          setState(() => _elapsedSeconds++);
        }
      });
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();

    if (_recorder?.state == 'recording') {
      _recorder!.stop();
    }

    await Future.delayed(const Duration(milliseconds: 500));

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
    final blob = html.Blob(_chunks, 'video/webm');
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);

    await reader.onLoad.first;

    final bytes = Uint8List.fromList(reader.result as List<int>);

    try {
      final client = Supabase.instance.client;
      final guestId = Get.parameters['guestId'] ?? '';
      if (guestId.isEmpty) throw Exception('Guest ID not found');

      final path =
          '$guestId/video_${DateTime.now().millisecondsSinceEpoch}.webm';
      await client.storage
          .from('guest-videos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

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
    } else {
      _recorder?.pause();
      setState(() => _isPaused = true);
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: HtmlElementView(
                  key: const ValueKey('video-preview'),
                  viewType: 'video-container',
                ),
              ),
            ),
            // Overlay UI
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  IconButton(
                    onPressed: () {
                      _stream?.getTracks().forEach((t) => t.stop());
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        if (_isRecording)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          ),
                        if (_isRecording) const SizedBox(width: 8),
                        Text(
                          _formatDuration(_elapsedSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Minimum duration indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _hasMinimumDuration
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _hasMinimumDuration
                          ? '✓ Min ${widget.minDurationSeconds}s'
                          : 'Min: ${widget.minDurationSeconds}s',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom controls
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_elapsedSeconds / 60).clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _hasMinimumDuration ? Colors.green : Colors.white,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pause/Resume
                      if (_isRecording)
                        GestureDetector(
                          onTap: _togglePause,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white24,
                            ),
                            child: Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (_isRecording) const SizedBox(width: 32),
                      // Record/Stop button
                      GestureDetector(
                        onTap: _isRecording
                            ? _stopRecording
                            : (_cameraReady ? _startRecording : null),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording ? Colors.red : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRecording
                        ? 'Appuyez pour arrêter'
                        : _cameraReady
                        ? 'Appuyez pour filmer'
                        : 'Chargement de la caméra...',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to render the video element via Dart interop
/// This creates an overlay element for camera preview
class VideoContainerElement {
  static void init() {
    // Create a div element for video preview
    final container = html.DivElement()
      ..id = 'video-container'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0';
    html.document.body?.append(container);
  }
}
