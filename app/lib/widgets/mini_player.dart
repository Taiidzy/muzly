import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/player_provider.dart';
import '../../utils/app_theme.dart';
import '../screens/now_playing_screen.dart';

/// Mini Player Widget
///
/// Displays at the bottom of screens when a track is playing
/// Tapping opens the full Now Playing screen
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  static const _desktopBreakpoint = 1024.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        final width = MediaQuery.sizeOf(context).width;
        final isDesktop = width >= _desktopBreakpoint;
        final track = player.currentTrack;

        if (track == null || isDesktop) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            _openNowPlaying(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    // Album art
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child:
                            track.albumArtUrl != null &&
                                track.albumArtUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: track.albumArtUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: AppTheme.bg),
                                errorWidget: (context, url, error) => Container(
                                  color: AppTheme.bg,
                                  child: const Icon(
                                    Icons.music_note,
                                    color: AppTheme.textDim,
                                    size: 20,
                                  ),
                                ),
                              )
                            : Container(
                                color: AppTheme.bg,
                                child: const Icon(
                                  Icons.music_note,
                                  color: AppTheme.textDim,
                                  size: 20,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Track info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: TextStyle(
                              fontFamily: 'IM Fell English',
                              fontSize: 14,
                              color: AppTheme.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artistName,
                            style: const TextStyle(
                              fontFamily: 'Inconsolata',
                              fontSize: 9,
                              color: AppTheme.textDim,
                              letterSpacing: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Play/Pause button
                    GestureDetector(
                      onTap: () => player.playPause(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.border, width: 1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          player.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 20,
                          color: AppTheme.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(_buildNowPlayingRoute());
  }

  Route<void> _buildNowPlayingRoute() {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const NowPlayingScreen(),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final offsetTween = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        );

        return SlideTransition(
          position: offsetTween.animate(curved),
          child: child,
        );
      },
    );
  }
}
