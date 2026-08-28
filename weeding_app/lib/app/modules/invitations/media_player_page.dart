import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/models/guest_media.dart';
import '../../data/models/guest.dart';

/// Waveform visualization styles
enum WaveformStyle {
  linear,
  rounded,
  random,
  sine,
  pulse,
}

extension WaveformStyleExtension on WaveformStyle {
  String get label {
    switch (this) {
      case WaveformStyle.linear:
        return 'Linéaire';
      case WaveformStyle.rounded:
        return 'Arrondi';
      case WaveformStyle.random:
        return 'Aléatoire';
      case WaveformStyle.sine:
        return 'Sinus';
      case WaveformStyle.pulse:
        return 'Pouls';
    }
  }

  IconData get icon {
    switch (this) {
      case WaveformStyle.linear:
        return Icons.linear_scale;
      case WaveformStyle.rounded:
        return Icons.rounded_corner;
      case WaveformStyle.random:
        return Icons.casino;
      case WaveformStyle.sine:
        return Icons.waves;
      case WaveformStyle.pulse:
        return Icons.favorite;
    }
  }

  List<double> generateBars(int count, Random random) {
    switch (this) {
      case WaveformStyle.linear:
        // Linear progression: small to tall to small
        return List.generate(
          count,
          (i) {
            final center = count / 2;
            final distance = (i - center).abs() / center;
            return 0.3 + (1 - distance) * 0.7;
          },
        );

      case WaveformStyle.rounded:
        // Rounded: high in center, low on edges with smooth curve
        return List.generate(
          count,
          (i) {
            final center = count / 2;
            final distance = (i - center).abs() / center;
            final curve = cos(distance * pi / 2);
            return 0.2 + curve * 0.8;
          },
        );

      case WaveformStyle.random:
        // Completely random bars
        return List.generate(
          count,
          (_) => 0.1 + random.nextDouble() * 0.9,
        );

      case WaveformStyle.sine:
        // Sine wave pattern
        return List.generate(
          count,
          (i) {
            final value = sin(i * 0.3) * 0.5 + 0.5;
            return 0.2 + value * 0.8;
          },
        );

      case WaveformStyle.pulse:
        // Pulse: alternating high and low
        return List.generate(
          count,
          (i) {
            if (i % 4 < 2) {
              return 0.8 + random.nextDouble() * 0.2;
            } else {
              return 0.2 + random.nextDouble() * 0.3;
            }
          },
        );
    }
  }
}

class MediaPlayerPage extends StatefulWidget {
  final Guest guest;
  final GuestMedia media;

  const MediaPlayerPage({
    super.key,
    required this.guest,
    required this.media,
  });

  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage>
    with TickerProviderStateMixin {
  final MediaRepository _mediaRepo = MediaRepository();

  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;

  bool _isLoading = true;
  bool _isPlaying = false;
  String? _mediaUrl;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _error;

  // Waveform state
  late AnimationController _waveformController;
  late List<double> _waveformBars;
  final int _barCount = 40;
  final Random _random = Random();
  WaveformStyle _waveformStyle = WaveformStyle.rounded;

  @override
  void initState() {
    super.initState();
    _initWaveform();
    _loadMedia();
  }

  void _initWaveform() {
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _generateBars();
    _waveformController.addListener(_updateWaveform);
  }

  void _generateBars() {
    _waveformBars = _waveformStyle.generateBars(_barCount, _random);
  }

  void _updateWaveform() {
    if (!_isPlaying) return;

    setState(() {
      _generateBars();
    });
  }

  void _changeWaveformStyle(WaveformStyle style) {
    setState(() {
      _waveformStyle = style;
      _generateBars();
    });
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);

    try {
      _mediaUrl = await _mediaRepo.getMediaDownloadUrl(
        widget.media.storagePath,
        widget.media.mediaType,
      );

      if (widget.media.mediaType == 'video') {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(_mediaUrl!));
        await _videoController!.initialize();
        _videoController!.addListener(_videoListener);
        setState(() {
          _duration = _videoController!.value.duration;
        });
      } else {
        _audioPlayer = AudioPlayer();
        await _audioPlayer!.setUrl(_mediaUrl!);
        _audioPlayer!.playerStateStream.listen((state) {
          setState(() {
            _isPlaying = state.playing;
            if (_isPlaying) {
              _waveformController.repeat();
            } else {
              _waveformController.stop();
            }
          });
        });
        _audioPlayer!.positionStream.listen((pos) {
          setState(() => _position = pos);
        });
        _audioPlayer!.durationStream.listen((dur) {
          if (dur != null) {
            setState(() => _duration = dur);
          }
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur lors du chargement du média: $e';
      });
    }
  }

  void _videoListener() {
    if (_videoController != null && mounted) {
      setState(() {
        _isPlaying = _videoController!.value.isPlaying;
        _position = _videoController!.value.position;
        _duration = _videoController!.value.duration;
      });
    }
  }

  void _togglePlayPause() {
    if (widget.media.mediaType == 'video' && _videoController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    } else if (_audioPlayer != null) {
      if (_audioPlayer!.playing) {
        _audioPlayer!.pause();
        _waveformController.stop();
      } else {
        _audioPlayer!.play();
        _waveformController.repeat();
      }
    }
  }

  void _seek(Duration position) {
    if (widget.media.mediaType == 'video' && _videoController != null) {
      _videoController!.seekTo(position);
    } else if (_audioPlayer != null) {
      _audioPlayer!.seek(position);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _waveformController.removeListener(_updateWaveform);
    _waveformController.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Média de ${widget.guest.fullName}',
          style: AppTextStyles.titleLg.copyWith(color: AppColors.dark),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? _buildErrorView()
              : _buildPlayerView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.statusPending,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLg.copyWith(color: AppColors.dark),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _loadMedia();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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

  Widget _buildPlayerView() {
    return Column(
      children: [
        // Media info header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.media.mediaType == 'video'
                      ? Icons.videocam
                      : Icons.mic,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.guest.fullName,
                      style: AppTextStyles.titleLg.copyWith(
                        color: AppColors.dark,
                      ),
                    ),
                    Text(
                      '${widget.media.mediaType == "video" ? "Vidéo" : "Audio"} • ${widget.media.durationFormatted}',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.media.isValid
                      ? AppColors.statusCardUnlocked.withValues(alpha: 0.1)
                      : AppColors.statusPending.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.media.isValid ? 'Validé' : 'En attente',
                  style: AppTextStyles.labelMd.copyWith(
                    color: widget.media.isValid
                        ? AppColors.statusCardUnlocked
                        : AppColors.statusPending,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Video player or audio visualizer
        Expanded(
          child: widget.media.mediaType == 'video'
              ? _buildVideoPlayer()
              : _buildAudioPlayer(),
        ),

        // Controls
        _buildControls(),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoController!),
            if (!_isPlaying)
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Waveform style selector
        _buildWaveformStyleSelector(),
        const SizedBox(height: 16),

        // Animated waveform
        _AudioWaveform(
          bars: _waveformBars,
          isPlaying: _isPlaying,
          barCount: _barCount,
          style: _waveformStyle,
        ),
        const SizedBox(height: 32),

        // Guest info
        Text(
          widget.guest.fullName,
          style: AppTextStyles.headlineLg.copyWith(
            color: AppColors.dark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Message audio',
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildWaveformStyleSelector() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: WaveformStyle.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final style = WaveformStyle.values[index];
          final isSelected = _waveformStyle == style;

          return GestureDetector(
            onTap: () => _changeWaveformStyle(style),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outlineVariant.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    style.icon,
                    size: 16,
                    color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    style.label,
                    style: AppTextStyles.labelMd.copyWith(
                      color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.outlineVariant,
              thumbColor: AppColors.primary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 4,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: _position.inSeconds.toDouble().clamp(
                    0,
                    _duration.inSeconds.toDouble(),
                  ),
              max: _duration.inSeconds.toDouble().clamp(1, double.infinity),
              onChanged: (value) {
                _seek(Duration(seconds: value.toInt()));
              },
            ),
          ),
          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rewind 10s
              _ControlButton(
                icon: Icons.replay_10,
                onTap: () {
                  final newPos = _position - const Duration(seconds: 10);
                  _seek(newPos.isNegative ? Duration.zero : newPos);
                },
              ),
              const SizedBox(width: 24),
              // Play/Pause
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Forward 10s
              _ControlButton(
                icon: Icons.forward_10,
                onTap: () {
                  final newPos = _position + const Duration(seconds: 10);
                  if (newPos > _duration) {
                    _seek(_duration);
                  } else {
                    _seek(newPos);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bottom action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Download or share
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Partager'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dark,
                    side: const BorderSide(color: AppColors.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to unlock card
                  },
                  icon: const Icon(Icons.credit_card, size: 18),
                  label: const Text('Débloquer carte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Animated audio waveform visualization
class _AudioWaveform extends StatelessWidget {
  final List<double> bars;
  final bool isPlaying;
  final int barCount;
  final WaveformStyle style;

  const _AudioWaveform({
    required this.bars,
    required this.isPlaying,
    required this.barCount,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          barCount,
          (index) {
            final baseHeight = isPlaying
                ? bars[index % bars.length] * 70
                : 20.0 + (sin(index * 0.5) * 10);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _getBarWidth(),
              height: baseHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.6),
                    AppColors.primary,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: _getBarRadius(),
                boxShadow: isPlaying
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  double _getBarWidth() {
    switch (style) {
      case WaveformStyle.linear:
        return 4;
      case WaveformStyle.rounded:
        return 5;
      case WaveformStyle.random:
        return 3;
      case WaveformStyle.sine:
        return 4;
      case WaveformStyle.pulse:
        return 6;
    }
  }

  BorderRadius _getBarRadius() {
    switch (style) {
      case WaveformStyle.rounded:
        return BorderRadius.circular(3);
      case WaveformStyle.pulse:
        return BorderRadius.circular(4);
      default:
        return BorderRadius.circular(2);
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.dark,
          size: 24,
        ),
      ),
    );
  }
}
