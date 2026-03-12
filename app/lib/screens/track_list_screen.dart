import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/player_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../widgets/mini_player.dart';

/// Track List Screen
///
/// Displays a list of tracks for an album or playlist
class TrackListScreen extends StatelessWidget {
  final String title;
  final List<Track> tracks;
  final String? subtitle;

  const TrackListScreen({
    super.key,
    required this.title,
    required this.tracks,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Track list
            Expanded(
              child: tracks.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                      itemCount: tracks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return _TrackListItem(
                          track: track,
                          index: index + 1,
                          onTap: () =>
                              player.playTrack(track, playlist: tracks),
                        );
                      },
                    ),
            ),

            // Mini Player
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 18),
                onPressed: () => Navigator.pop(context),
                color: AppTheme.textDim,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'IM Fell English',
                        fontSize: 18,
                        color: AppTheme.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontFamily: 'Inconsolata',
                          fontSize: 10,
                          color: AppTheme.textDim,
                          letterSpacing: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Play all button
              GestureDetector(
                onTap: tracks.isNotEmpty
                    ? () {
                        final player = Provider.of<PlayerProvider>(
                          context,
                          listen: false,
                        );
                        player.playPlaylist(tracks);
                      }
                    : null,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border, width: 1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 18,
                    color: AppTheme.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Track count
          Text(
            '${tracks.length} ${tracks.length == 1 ? 'TRACK' : 'TRACKS'}',
            style: const TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 9,
              color: AppTheme.textDim,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_note, color: AppTheme.textDim, size: 48),
          const SizedBox(height: 16),
          Text(
            'No tracks',
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 12,
              color: AppTheme.text,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Track list item
class _TrackListItem extends StatelessWidget {
  final Track track;
  final int index;
  final VoidCallback onTap;

  const _TrackListItem({
    required this.track,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final isPlaying = player.currentTrack?.id == track.id;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: Row(
          children: [
            // Track number or playing indicator
            SizedBox(
              width: 24,
              child: Center(
                child: isPlaying && player.isPlaying
                    ? const _PlayingIndicator()
                    : Text(
                        '$index',
                        style: const TextStyle(
                          fontFamily: 'Inconsolata',
                          fontSize: 10,
                          color: AppTheme.textDim,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Album art (small)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child:
                    track.albumArtUrl != null && track.albumArtUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: track.albumArtUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: AppTheme.surface),
                        errorWidget: (context, url, error) =>
                            Container(color: AppTheme.surface),
                      )
                    : Container(
                        color: AppTheme.surface,
                        child: const Icon(
                          Icons.music_note,
                          color: AppTheme.textDim,
                          size: 16,
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
                      color: isPlaying ? AppTheme.accent : AppTheme.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artistName,
                    style: const TextStyle(
                      fontFamily: 'Inconsolata',
                      fontSize: 10,
                      color: AppTheme.textDim,
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Duration
            Text(
              track.formattedDuration,
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
    );
  }
}

/// Playing indicator (animated bars)
class _PlayingIndicator extends StatefulWidget {
  const _PlayingIndicator();

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBar(0.3),
            const SizedBox(width: 1),
            _buildBar(0.6),
            const SizedBox(width: 1),
            _buildBar(0.9),
          ],
        );
      },
    );
  }

  Widget _buildBar(double heightFactor) {
    final height = 4 + (8 * heightFactor * _controller.value);
    return Container(width: 2, height: height, color: AppTheme.accent);
  }
}
