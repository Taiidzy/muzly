import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/player_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_list_tile.dart';
import 'track_list_screen.dart';

/// Library Screen
///
/// Displays user's library with tabs for playlists, albums, and artists
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = Provider.of<PlayerProvider>(context, listen: false);
      if (player.playlists.isEmpty && player.tracks.isEmpty) {
        player.loadLibrary();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

            // Tabs
            _buildTabs(),

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

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Playlists tab
                      _buildPlaylistsTab(player.playlists),

                      // Tracks tab
                      _buildTracksTab(player.tracks),
                    ],
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
            'LIBRARY',
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 14,
              letterSpacing: 3,
              color: AppTheme.text,
            ),
          ),
          Row(
            children: [
              Text(
                'ライブラリ',
                style: TextStyle(
                  fontFamily: 'Noto Serif JP',
                  fontSize: 10,
                  color: AppTheme.textDim,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              // Logout button
              GestureDetector(
                onTap: () {
                  final auth = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  auth.logout();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border, width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'LOGOUT',
                    style: TextStyle(
                      fontFamily: 'Inconsolata',
                      fontSize: 9,
                      color: AppTheme.textDim,
                      letterSpacing: 1,
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

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.accent,
        unselectedLabelColor: AppTheme.textDim,
        indicatorColor: AppTheme.accent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontFamily: 'Inconsolata',
          fontSize: 10,
          letterSpacing: 2,
        ),
        tabs: const [
          Tab(text: 'PLAYLISTS'),
          Tab(text: 'TRACKS'),
        ],
      ),
    );
  }

  Widget _buildPlaylistsTab(List<Playlist> playlists) {
    if (playlists.isEmpty) {
      return _buildEmptyState('No playlists yet');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(22),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        return _PlaylistGridItem(playlist: playlists[index]);
      },
    );
  }

  Widget _buildTracksTab(List<Track> tracks) {
    if (tracks.isEmpty) {
      return _buildEmptyState('No tracks yet');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
      itemCount: tracks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        return TrackListTile(track: tracks[index]);
      },
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 8,
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
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
              'Failed to load library',
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, color: AppTheme.textDim, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
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

/// Playlist grid item
class _PlaylistGridItem extends StatelessWidget {
  final Playlist playlist;

  const _PlaylistGridItem({required this.playlist});

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
                    : Container(
                        color: AppTheme.surface,
                        child: const Icon(
                          Icons.playlist_play,
                          color: AppTheme.textDim,
                          size: 32,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.title,
            style: TextStyle(
              fontFamily: 'IM Fell English',
              fontSize: 14,
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
    );
  }
}
