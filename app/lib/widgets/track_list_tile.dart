import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/player_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';

/// Track List Tile Widget
///
/// Displays a single track in a list with album art, title, artist, and duration
class TrackListTile extends StatelessWidget {
  final Track track;
  final bool showAlbum;
  final VoidCallback? onTap;

  const TrackListTile({
    super.key,
    required this.track,
    this.showAlbum = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final isPlaying = player.currentTrack?.id == track.id;

    return GestureDetector(
      onTap: onTap ?? () => player.playTrack(track),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: Row(
          children: [
            // Album art
            Container(
              width: 50,
              height: 50,
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
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.surface,
                          child: const Icon(
                            Icons.music_note,
                            color: AppTheme.textDim,
                            size: 20,
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.surface,
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
                      color: isPlaying ? AppTheme.accent : AppTheme.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
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
                  if (showAlbum) ...[
                    const SizedBox(height: 2),
                    Text(
                      track.albumName,
                      style: const TextStyle(
                        fontFamily: 'Inconsolata',
                        fontSize: 9,
                        color: AppTheme.textMuted,
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Options menu
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: AppTheme.textDim,
                size: 20,
              ),
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: AppTheme.border),
              ),
              onSelected: (value) {
                if (value == 'play_next') {
                  player.playNext(track);
                } else if (value == 'add_to_queue') {
                  player.addToQueue(track);
                } else if (value == 'like') {
                  player.toggleLike();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'play_next',
                  child: Text(
                    'Play Next',
                    style: TextStyle(
                      fontFamily: 'Inconsolata',
                      fontSize: 10,
                      color: AppTheme.text,
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_to_queue',
                  child: Text(
                    'Add to Queue',
                    style: TextStyle(
                      fontFamily: 'Inconsolata',
                      fontSize: 10,
                      color: AppTheme.text,
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'like',
                  child: Text(
                    'Add to Favorites',
                    style: TextStyle(
                      fontFamily: 'Inconsolata',
                      fontSize: 10,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

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
