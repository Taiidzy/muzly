import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/player_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_list_tile.dart';
import '../widgets/skeleton_loader.dart';
import 'track_list_screen.dart';

/// Home Screen
///
/// Displays recently played, featured tracks, and quick access sections
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load library data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = Provider.of<PlayerProvider>(context, listen: false);
      if (player.tracks.isEmpty) {
        player.loadLibrary();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: Consumer<PlayerProvider>(
                builder: (context, player, child) {
                  if (player.isLoadingLibrary) {
                    return _buildLoadingState();
                  }

                  if (player.libraryError != null) {
                    return _buildErrorState(player.libraryError!);
                  }

                  if (player.tracks.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () => player.loadLibrary(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recently Played (from history)
                          _buildSection(
                            title: 'RECENTLY PLAYED',
                            child: _buildRecentlyPlayed(
                              player.recentTracks.isNotEmpty
                                  ? player.recentTracks
                                  : player.tracks,
                            ),
                          ),

                          // Featured Playlists
                          _buildSection(
                            title: 'FEATURED PLAYLISTS',
                            child: _buildFeaturedPlaylists(
                              player.featuredPlaylists,
                            ),
                          ),

                          // All Tracks
                          _buildSection(
                            title: 'ALL TRACKS',
                            child: _buildAllTracks(player.tracks),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MUZLY',
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 16,
              letterSpacing: 4,
              color: AppTheme.text,
              fontWeight: FontWeight.w300,
            ),
          ),
          Text(
            '夜の音楽',
            style: TextStyle(
              fontFamily: 'Noto Serif JP',
              fontSize: 10,
              color: AppTheme.textDim,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inconsolata',
                fontSize: 9,
                letterSpacing: 3,
                color: AppTheme.textDim,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildRecentlyPlayed(List<Track> tracks) {
    final recentTracks = tracks.take(5).toList();

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: recentTracks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final track = recentTracks[index];
          return _RecentTrackCard(track: track);
        },
      ),
    );
  }

  Widget _buildFeaturedPlaylists(List<Playlist> playlists) {
    if (playlists.isEmpty) {
      // Show placeholder if no playlists
      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return _PlaylistCard(
              playlist: Playlist(
                id: 'placeholder_$index',
                title: 'Playlist ${index + 1}',
                trackCount: 0,
              ),
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: playlists.length.clamp(0, 10),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return _PlaylistCard(playlist: playlist);
        },
      ),
    );
  }

  Widget _buildAllTracks(List<Track> tracks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: tracks.take(10).map((track) {
          return TrackListTile(track: track);
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const SkeletonLoader(height: 24, width: 150),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => const SkeletonLoader(
                width: 140,
                height: 180,
                borderRadius: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => const SkeletonLoader(
                width: 160,
                height: 200,
                borderRadius: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.textDim, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load content',
              style: TextStyle(
                fontFamily: 'Inconsolata',
                fontSize: 12,
                color: AppTheme.text,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: AppTheme.textDim),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final player = Provider.of<PlayerProvider>(
                  context,
                  listen: false,
                );
                player.loadLibrary();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surface,
                foregroundColor: AppTheme.text,
              ),
            ),
          ],
        ),
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
            'No music available',
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 12,
              color: AppTheme.text,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your connection or try again later',
            style: TextStyle(fontSize: 10, color: AppTheme.textDim),
          ),
        ],
      ),
    );
  }
}

/// Recent track card
class _RecentTrackCard extends StatelessWidget {
  final Track track;

  const _RecentTrackCard({required this.track});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context, listen: false);

    return GestureDetector(
      onTap: () => player.playTrack(track),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
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
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.surface,
                          child: const Icon(
                            Icons.music_note,
                            color: AppTheme.textDim,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
    );
  }
}

/// Playlist card
class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackListScreen(
              title: playlist.title,
              tracks: playlist.tracks ?? [],
              subtitle: playlist.creatorName,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.border, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child:
                      playlist.coverUrl != null && playlist.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: playlist.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: AppTheme.surface),
                          errorWidget: (context, url, error) =>
                              Container(color: AppTheme.surface),
                        )
                      : Container(color: AppTheme.surface),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist.title,
              style: TextStyle(
                fontFamily: 'IM Fell English',
                fontSize: 13,
                color: AppTheme.text,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${playlist.trackCount} tracks',
              style: const TextStyle(
                fontFamily: 'Inconsolata',
                fontSize: 9,
                color: AppTheme.textDim,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
