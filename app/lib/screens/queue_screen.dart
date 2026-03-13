import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/player_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';

/// Queue Screen
///
/// Displays the current playback queue with management options:
/// - View all queued tracks
/// - Remove tracks from queue
/// - Reorder tracks (drag & drop)
/// - Clear queue
/// - Play next functionality
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'QUEUE',
          style: TextStyle(
            fontFamily: 'Inconsolata',
            fontSize: 14,
            letterSpacing: 3,
            color: AppTheme.text,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<PlayerProvider>(
            builder: (context, player, child) {
              if (player.queue.length <= 1) return const SizedBox.shrink();
              
              return TextButton(
                onPressed: () {
                  _showClearQueueDialog(context, player);
                },
                child: const Text(
                  'CLEAR',
                  style: TextStyle(
                    fontFamily: 'Inconsolata',
                    fontSize: 10,
                    color: AppTheme.accent,
                    letterSpacing: 1,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, player, child) {
          final queue = player.queue;
          final currentIndex = player.currentTrackIndex;

          if (queue.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Queue info
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${queue.length} tracks',
                      style: const TextStyle(
                        fontFamily: 'Inconsolata',
                        fontSize: 10,
                        color: AppTheme.textDim,
                        letterSpacing: 1,
                      ),
                    ),
                    if (currentIndex >= 0 && currentIndex < queue.length)
                      Text(
                        'Playing: ${currentIndex + 1}/${queue.length}',
                        style: const TextStyle(
                          fontFamily: 'Inconsolata',
                          fontSize: 10,
                          color: AppTheme.accent,
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              ),

              // Queue list
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                  itemCount: queue.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) newIndex--;
                    player.moveTrackInQueue(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final track = queue[index];
                    final isPlaying = index == currentIndex;

                    return _QueueTrackTile(
                      key: ValueKey(track.id),
                      track: track,
                      isPlaying: isPlaying,
                      index: index,
                      onRemove: () {
                        player.removeFromQueue(track.id);
                      },
                      onPlayNext: () {
                        player.removeFromQueue(track.id);
                        player.playNext(track);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.queue_music,
            color: AppTheme.textDim,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Queue is empty',
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 12,
              color: AppTheme.text,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add tracks to start listening',
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 10,
              color: AppTheme.textDim,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearQueueDialog(BuildContext context, PlayerProvider player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text(
          'Clear Queue?',
          style: TextStyle(
            fontFamily: 'Inconsolata',
            color: AppTheme.text,
          ),
        ),
        content: const Text(
          'This will remove all tracks from the queue except the currently playing track.',
          style: TextStyle(
            fontFamily: 'Inconsolata',
            fontSize: 10,
            color: AppTheme.textDim,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: 'Inconsolata',
                color: AppTheme.textDim,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              player.clearQueue();
              Navigator.pop(context);
            },
            child: const Text(
              'CLEAR',
              style: TextStyle(
                fontFamily: 'Inconsolata',
                color: AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Queue track tile with drag handle and remove option
class _QueueTrackTile extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onPlayNext;

  const _QueueTrackTile({
    required this.track,
    required this.isPlaying,
    required this.index,
    required this.onRemove,
    required this.onPlayNext,
    key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isPlaying ? AppTheme.surface : Colors.transparent,
        border: Border.all(
          color: isPlaying ? AppTheme.border : Colors.transparent,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                // Cover art
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: track.albumArtUrl != null && track.albumArtUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: track.albumArtUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.surface,
                          ),
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
                // Playing indicator
                if (isPlaying)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.7),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.equalizer,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          title: Text(
            track.title,
            style: TextStyle(
              fontFamily: 'IM Fell English',
              fontSize: 13,
              color: isPlaying ? AppTheme.accent : AppTheme.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track.artist,
            style: const TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 9,
              color: AppTheme.textDim,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Track number or drag handle
              SizedBox(
                width: 24,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontFamily: 'Inconsolata',
                    fontSize: 9,
                    color: AppTheme.textDim,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // More options menu
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
                  if (value == 'remove') {
                    onRemove();
                  } else if (value == 'play_next') {
                    onPlayNext();
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
                    value: 'remove',
                    child: Text(
                      'Remove from Queue',
                      style: TextStyle(
                        fontFamily: 'Inconsolata',
                        fontSize: 10,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                ],
              ),
              // Drag handle
              const ReorderableDragStartListener(
                index: 0,
                child: Icon(
                  Icons.drag_handle,
                  color: AppTheme.textDim,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
