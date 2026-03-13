import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../providers/player_provider.dart';
import '../../utils/app_theme.dart';
import 'queue_screen.dart';

/// Now Playing Screen
///
/// Matches the player.html design with:
/// - Night city artwork with SVG-like aesthetic
/// - Minimal typography (Noto Serif JP, IM Fell English, Inconsolata)
/// - Waveform visualization
/// - Subtle gradients and muted colors
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final _waveformKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Consumer<PlayerProvider>(
          builder: (context, player, child) {
            final track = player.currentTrack;

            if (track == null) {
              return const Center(
                child: Text(
                  'NO TRACK PLAYING',
                  style: TextStyle(
                    fontFamily: 'Inconsolata',
                    fontSize: 10,
                    letterSpacing: 3,
                    color: AppTheme.textDim,
                  ),
                ),
              );
            }

            return GestureDetector(
              onVerticalDragUpdate: (details) {
                // Close on swipe down
                if (details.delta.dy > 10) {
                  Navigator.pop(context);
                }
              },
              child: Column(
                children: [
                  // Album Art Section
                  _AlbumArtSection(
                    key: ValueKey(track.id),
                    albumArtUrl: track.cover800Url,
                    albumName: track.albumName,
                  ),

                  // Track Info and Controls
                  Expanded(
                    child: _BodySection(
                      track: track,
                      isPlaying: player.isPlaying,
                      isLoading: player.isLoading,
                      position: player.position,
                      duration: player.duration,
                      progress: player.progress,
                      isShuffle: player.isShuffle,
                      loopMode: player.loopMode,
                      isLiked: player.isLiked(track.id),
                      waveformKey: _waveformKey,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Album Art Section with night city aesthetic
class _AlbumArtSection extends StatefulWidget {
  final String? albumArtUrl;
  final String albumName;

  const _AlbumArtSection({
    super.key,
    required this.albumArtUrl,
    required this.albumName,
  });

  @override
  State<_AlbumArtSection> createState() => _AlbumArtSectionState();
}

class _AlbumArtSectionState extends State<_AlbumArtSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border.withAlpha(77), width: 1),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Album art or placeholder
              if (widget.albumArtUrl != null && widget.albumArtUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: widget.albumArtUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildPlaceholder(),
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),

              // Gradient fade at bottom
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      AppTheme.surface.withAlpha(153),
                      AppTheme.surface,
                    ],
                    stops: const [0.0, 0.55, 0.82, 1.0],
                  ),
                ),
              ),

              // Formula text (decorative, like in player.html)
              Positioned(
                top: 12,
                right: 12,
                child: Text(
                  'H₂O · NaCl\n273 K',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Inconsolata',
                    fontSize: 8,
                    color: Colors.white.withAlpha(26),
                    height: 1.8,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF090A0D),
      child: CustomPaint(painter: _NightCityPainter()),
    );
  }
}

/// Custom painter for night city scene (mimics the SVG in player.html)
class _NightCityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Sky gradient
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF141820),
        const Color(0xFF0E1116),
        const Color(0xFF09090D),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    paint.shader = skyGradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Stars
    paint.shader = null;
    paint.color = Colors.white.withValues(alpha: 0.5);
    _drawStars(canvas, paint, size);

    // Moon
    paint.color = const Color(0xFFC2CCD8).withValues(alpha: 0.82);
    canvas.drawCircle(
      Offset(size.width * 0.73, size.height * 0.27),
      size.width * 0.11,
      paint,
    );

    // Clouds
    paint.color = const Color(0xFF181E28);
    _drawClouds(canvas, paint, size);

    // Mountains
    paint.color = const Color(0xFF0C1018);
    _drawMountains(canvas, paint, size);

    // City buildings
    paint.color = const Color(0xFF090B12);
    _drawCity(canvas, paint, size);

    // Windows
    paint.color = const Color(0xFFC0A060).withAlpha(77);
    _drawWindows(canvas, paint, size);
  }

  void _drawStars(Canvas canvas, Paint paint, Size size) {
    final starPositions = [
      Offset(size.width * 0.09, size.height * 0.07),
      Offset(size.width * 0.24, size.height * 0.04),
      Offset(size.width * 0.43, size.height * 0.09),
      Offset(size.width * 0.62, size.height * 0.03),
      Offset(size.width * 0.81, size.height * 0.06),
      Offset(size.width * 0.15, size.height * 0.18),
      Offset(size.width * 0.34, size.height * 0.15),
      Offset(size.width * 0.53, size.height * 0.05),
      Offset(size.width * 0.72, size.height * 0.16),
    ];

    for (final pos in starPositions) {
      canvas.drawCircle(pos, 1.5, paint);
    }
  }

  void _drawClouds(Canvas canvas, Paint paint, Size size) {
    final y = size.height * 0.46;
    canvas.drawOval(Rect.fromLTWH(0, y - 30, size.width * 0.29, 30), paint);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.2, y - 24, size.width * 0.19, 24),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.35, y - 28, size.width * 0.25, 28),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.7, y - 32, size.width * 0.35, 32),
      paint,
    );
  }

  void _drawMountains(Canvas canvas, Paint paint, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.73);
    path.lineTo(size.width * 0.13, size.height * 0.54);
    path.lineTo(size.width * 0.26, size.height * 0.62);
    path.lineTo(size.width * 0.39, size.height * 0.49);
    path.lineTo(size.width * 0.51, size.height * 0.59);
    path.lineTo(size.width * 0.64, size.height * 0.51);
    path.lineTo(size.width * 0.79, size.height * 0.56);
    path.lineTo(size.width * 0.91, size.height * 0.48);
    path.lineTo(size.width, size.height * 0.54);
    path.lineTo(size.width, size.height * 0.73);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCity(Canvas canvas, Paint paint, Size size) {
    final baseY = size.height * 0.66;
    final buildings = [
      Rect.fromLTWH(0, baseY - 20, 18, 40),
      Rect.fromLTWH(12, baseY - 10, 22, 30),
      Rect.fromLTWH(28, baseY - 30, 15, 50),
      Rect.fromLTWH(38, baseY - 15, 20, 35),
      Rect.fromLTWH(52, baseY - 25, 12, 45),
      Rect.fromLTWH(58, baseY - 12, 25, 32),
      Rect.fromLTWH(76, baseY - 35, 18, 55),
      Rect.fromLTWH(88, baseY - 18, 22, 38),
      Rect.fromLTWH(104, baseY - 28, 14, 48),
      Rect.fromLTWH(112, baseY - 22, 28, 42),
    ];

    for (final rect in buildings) {
      canvas.drawRect(rect.translate(0, size.height * 0.2), paint);
    }
  }

  void _drawWindows(Canvas canvas, Paint paint, Size size) {
    final baseY = size.height * 0.66;
    final windowPositions = [
      Offset(2, baseY - 15),
      Offset(2, baseY - 5),
      Offset(30, baseY - 20),
      Offset(60, baseY - 10),
      Offset(78, baseY - 25),
      Offset(92, baseY - 15),
      Offset(114, baseY - 18),
    ];

    for (final pos in windowPositions) {
      canvas.drawRect(
        Rect.fromLTWH(pos.dx, pos.dy + size.height * 0.2, 3, 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Body section with track info and controls
class _BodySection extends StatelessWidget {
  final dynamic track;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final double progress;
  final bool isShuffle;
  final dynamic loopMode;
  final bool isLiked;
  final Key waveformKey;

  const _BodySection({
    required this.track,
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.duration,
    required this.progress,
    required this.isShuffle,
    required this.loopMode,
    required this.isLiked,
    required this.waveformKey,
  });

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Japanese text (decorative)
          Text(
            '夜の静寂',
            style: TextStyle(
              fontFamily: 'Noto Serif JP',
              fontSize: 9,
              fontWeight: FontWeight.w300,
              color: AppTheme.textDim,
              letterSpacing: 5,
            ),
          ),

          const SizedBox(height: 7),

          // Track title
          Text(
            track.title,
            style: TextStyle(
              fontFamily: 'IM Fell English',
              fontSize: 21,
              letterSpacing: 0.3,
              height: 1.2,
              color: AppTheme.text,
            ),
          ),

          const SizedBox(height: 5),

          // Artist name
          Text(
            '${track.artistName} · ${track.albumName}',
            style: const TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 10,
              color: AppTheme.textDim,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 18),

          // Waveform visualization
          KeyedSubtree(
            key: waveformKey,
            child: _Waveform(isPlaying: isPlaying, progress: progress),
          ),

          // Time display
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: const TextStyle(
                    fontFamily: 'Inconsolata',
                    fontSize: 9,
                    color: AppTheme.accent,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    fontFamily: 'Inconsolata',
                    fontSize: 9,
                    color: AppTheme.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          _ProgressBar(
            progress: progress,
            onSeek: (value) => player.seek(value),
          ),

          const SizedBox(height: 20),

          // Main controls
          _Controls(
            isPlaying: isPlaying,
            isLoading: isLoading,
            isShuffle: isShuffle,
            loopMode: loopMode,
            onPlayPause: () => player.playPause(),
            onNext: () => player.skipNext(),
            onPrevious: () => player.skipPrevious(),
            onToggleShuffle: () => player.toggleShuffle(),
            onCycleLoop: () => player.cycleLoopMode(),
          ),

          const SizedBox(height: 12),

          // Bottom row with like and queue buttons
          _BottomRow(
            isLiked: isLiked,
            onToggleLike: () => player.toggleLike(),
            onOpenQueue: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QueueScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Waveform visualization with music-reactive animation
class _Waveform extends StatefulWidget {
  final bool isPlaying;
  final double progress;

  const _Waveform({required this.isPlaying, required this.progress});

  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<double> _baseHeights;
  late List<double> _currentHeights;
  
  // Simulated frequency bands (bass, mid, treble)
  late List<double> _frequencyBands;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Generate base heights for waveform bars (simulating a waveform pattern)
    _baseHeights = List.generate(40, (index) {
      // Create a more natural waveform pattern
      final normalizedIndex = index / 39.0;
      final baseHeight = 8 + (normalizedIndex * 12);
      final variation = (index % 5) * 3;
      return baseHeight + variation;
    });

    _currentHeights = List.from(_baseHeights);
    
    // Initialize frequency bands
    _frequencyBands = List.filled(4, 1.0);

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Waveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _controller.stop();
        // Reset heights when paused
        setState(() {
          _currentHeights = List.from(_baseHeights);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateHeights() {
    // Update frequency bands with some randomness to simulate music reaction
    for (int i = 0; i < _frequencyBands.length; i++) {
      final target = 0.8 + (_random.nextDouble() * 0.4);
      _frequencyBands[i] = math.max(_frequencyBands[i], target) * 0.2 + _frequencyBands[i] * 0.8;
    }
    
    // Update bar heights based on frequency bands
    for (int i = 0; i < 40; i++) {
      final bandIndex = (i / 40.0 * _frequencyBands.length).floor();
      final bandMultiplier = _frequencyBands[bandIndex.clamp(0, 3)];
      final noise = (i % 3) * 2 * _controller.value;
      _currentHeights[i] = _baseHeights[i] * bandMultiplier + noise;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        _updateHeights();
        
        return SizedBox(
          height: 22,
          child: Row(
            children: List.generate(40, (index) {
              final normalizedIndex = index / 40;
              final isPast = normalizedIndex <= widget.progress;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: isPast ? AppTheme.textMuted : AppTheme.accent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                  height: _currentHeights[index].clamp(6, 22),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Progress bar with custom styling
class _ProgressBar extends StatelessWidget {
  final double progress;
  final ValueChanged<Duration> onSeek;

  const _ProgressBar({required this.progress, required this.onSeek});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppTheme.accent,
        inactiveTrackColor: AppTheme.textMuted,
        thumbColor: AppTheme.text,
        overlayColor: AppTheme.accent.withAlpha(77),
        trackHeight: 1,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3.5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
      ),
      child: Slider(
        value: progress.clamp(0.0, 1.0),
        onChanged: (value) {
          final player = Provider.of<PlayerProvider>(context, listen: false);
          final position = Duration(
            milliseconds: (value * player.duration.inMilliseconds).round(),
          );
          onSeek(position);
        },
      ),
    );
  }
}

/// Control buttons
class _Controls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final bool isShuffle;
  final dynamic loopMode;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onToggleShuffle;
  final VoidCallback onCycleLoop;

  const _Controls({
    required this.isPlaying,
    required this.isLoading,
    required this.isShuffle,
    required this.loopMode,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onToggleShuffle,
    required this.onCycleLoop,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = AppTheme.textDim;
    final activeColor = AppTheme.accent;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Shuffle button
        _ControlButton(
          icon: _shuffleIcon(isShuffle ? activeColor : iconColor),
          isActive: isShuffle,
          onTap: onToggleShuffle,
        ),

        // Previous button
        _ControlButton(icon: _previousIcon(iconColor), onTap: onPrevious),

        // Play/Pause button
        _PlayButton(
          isPlaying: isPlaying,
          isLoading: isLoading,
          onTap: onPlayPause,
        ),

        // Next button
        _ControlButton(icon: _nextIcon(iconColor), onTap: onNext),

        // Loop button
        _ControlButton(
          icon: _loopIcon(loopMode.toString() != 'LoopMode.off' ? activeColor : iconColor),
          isActive: loopMode.toString() != 'LoopMode.off',
          onTap: onCycleLoop,
        ),
      ],
    );
  }

  // SVG-like icons
  Widget _shuffleIcon(Color color) =>
      _SvgPath('M16 3l5 5-5 5M4 20l21-17M21 16l-5 5-5-5M3 4l17 17', color: color);

  Widget _previousIcon(Color color) => _SvgPath('M19 20L9 12l10-8v16zM5 19V5', color: color);

  Widget _nextIcon(Color color) => _SvgPath('M5 4l10 8-10 8V4zM19 5v14', color: color);

  Widget _loopIcon(Color color) => _SvgPath(
    'M17 1l4 4-4 4M3 11V9a4 4 0 014-4h14M7 23l-4-4 4-4M21 13v2a4 4 0 01-4 4H3',
    color: color,
  );
}

/// Simple SVG path renderer
class _SvgPath extends StatelessWidget {
  final String pathData;
  final Color? color;
  final double size;

  const _SvgPath(this.pathData, {this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PathPainter(pathData, color: color, strokeWidth: 2),
    );
  }
}

class _PathPainter extends CustomPainter {
  final String pathData;
  final Color? color;
  final double strokeWidth;

  _PathPainter(this.pathData, {this.color, this.strokeWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? AppTheme.textDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = _parsePath(pathData, size);
    canvas.drawPath(path, paint);
  }

  Path _parsePath(String data, Size size) {
    final path = Path();
    final commands = data.split(RegExp(r'(?=[A-Z])'));

    double currentX = 0;
    double currentY = 0;

    // Normalize coordinates to fit within size
    const maxCoord = 24.0;
    final scaleX = size.width / maxCoord;
    final scaleY = size.height / maxCoord;

    for (final command in commands) {
      if (command.isEmpty) continue;

      final type = command[0];
      final coords = command
          .substring(1)
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .map((s) => double.tryParse(s) ?? 0.0)
          .toList();

      switch (type) {
        case 'M':
          currentX = coords[0] * scaleX;
          currentY = coords[1] * scaleY;
          path.moveTo(currentX, currentY);
          break;
        case 'L':
          currentX = coords[0] * scaleX;
          currentY = coords[1] * scaleY;
          path.lineTo(currentX, currentY);
          break;
        case 'H':
          currentX = coords[0] * scaleX;
          path.lineTo(currentX, currentY);
          break;
        case 'V':
          currentY = coords[0] * scaleY;
          path.lineTo(currentX, currentY);
          break;
        case 'Q':
          final x1 = coords[0] * scaleX;
          final y1 = coords[1] * scaleY;
          currentX = coords[2] * scaleX;
          currentY = coords[3] * scaleY;
          path.quadraticBezierTo(x1, y1, currentX, currentY);
          break;
        case 'C':
          final x1 = coords[0] * scaleX;
          final y1 = coords[1] * scaleY;
          final x2 = coords[2] * scaleX;
          final y2 = coords[3] * scaleY;
          currentX = coords[4] * scaleX;
          currentY = coords[5] * scaleY;
          path.cubicTo(x1, y1, x2, y2, currentX, currentY);
          break;
        case 'Z':
          path.close();
          break;
      }
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Play button with larger size
class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  const _PlayButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withAlpha(23), width: 1),
          color: Colors.white.withAlpha(8),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.text),
                  ),
                )
              : CustomPaint(
                  size: const Size(17, 17),
                  painter: isPlaying ? _PlayIconPainter() : _PauseIconPainter(),
                ),
        ),
      ),
    );
  }
}

class _PlayIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.text
      ..style = PaintingStyle.fill;

    // Triangle for play
    final path = Path();
    path.moveTo(size.width * 0.3, 0);
    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(size.width * 0.3, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PauseIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.text
      ..style = PaintingStyle.fill;

    // Two rectangles for pause
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.4, size.height), paint);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.6, 0, size.width * 0.4, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Small control button
class _ControlButton extends StatelessWidget {
  final Widget icon;
  final bool isActive;
  final VoidCallback? onTap;

  const _ControlButton({required this.icon, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(shape: BoxShape.circle),
        child: Center(
          child: icon,
        ),
      ),
    );
  }
}

/// Bottom row with like, queue, share buttons
class _BottomRow extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onToggleLike;
  final VoidCallback onOpenQueue;

  const _BottomRow({
    required this.isLiked,
    required this.onToggleLike,
    required this.onOpenQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Like button
        _BottomButton(
          icon: _heartIcon(isLiked),
          label: 'LIKE',
          isActive: isLiked,
          onTap: onToggleLike,
        ),

        // Divider
        Container(width: 1, height: 14, color: AppTheme.border),

        // Queue button
        _BottomButton(
          icon: _queueIcon,
          label: 'QUEUE',
          onTap: onOpenQueue,
        ),

        // Divider
        Container(width: 1, height: 14, color: AppTheme.border),

        // Share button
        _BottomButton(
          icon: _shareIcon,
          label: 'SHARE',
          onTap: () {
            // TODO: Implement share
          },
        ),
      ],
    );
  }

  Widget _heartIcon(bool isLiked) => CustomPaint(
    size: const Size(13, 13),
    painter: _HeartIconPainter(isLiked),
  );

  Widget get _queueIcon =>
      _SvgPath('M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01');

  Widget get _shareIcon => _SvgPath(
    'M18 5a3 3 0 100-6 3 3 0 000 6zM6 12a3 3 0 100-6 3 3 0 000 6zM18 19a3 3 0 100-6 3 3 0 000 6zM8.59 13.51l6.82 3.99M15.41 6.51l-6.82 3.99',
  );
}

class _HeartIconPainter extends CustomPainter {
  final bool isFilled;

  _HeartIconPainter(this.isFilled);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isFilled ? AppTheme.liked.withAlpha(191) : AppTheme.textMuted
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.9);
    path.cubicTo(
      size.width * 0.1,
      size.height * 0.6,
      0,
      size.height * 0.35,
      0,
      size.height * 0.25,
    );
    path.cubicTo(
      0,
      size.height * 0.1,
      size.width * 0.15,
      0,
      size.width * 0.3,
      0,
    );
    path.cubicTo(
      size.width * 0.42,
      0,
      size.width * 0.5,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.1,
    );
    path.cubicTo(
      size.width * 0.5,
      size.height * 0.1,
      size.width * 0.58,
      0,
      size.width * 0.7,
      0,
    );
    path.cubicTo(
      size.width * 0.85,
      0,
      size.width,
      size.height * 0.1,
      size.width,
      size.height * 0.25,
    );
    path.cubicTo(
      size.width,
      size.height * 0.35,
      size.width * 0.9,
      size.height * 0.6,
      size.width * 0.5,
      size.height * 0.9,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartIconPainter other) =>
      isFilled != other.isFilled;
}

/// Bottom button with icon and label
class _BottomButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _BottomButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(
              color: isActive
                  ? AppTheme.liked.withAlpha(191)
                  : AppTheme.textMuted,
              size: 13,
            ),
            child: icon,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 9,
              letterSpacing: 1.5,
              color: isActive
                  ? AppTheme.liked.withAlpha(191)
                  : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
