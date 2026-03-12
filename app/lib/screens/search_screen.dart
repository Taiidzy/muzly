import 'package:flutter/material.dart';
import 'package:muzly/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/player_provider.dart';
import '../../models/models.dart';
import '../../utils/app_theme.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_list_tile.dart';
import '../widgets/skeleton_loader.dart';
import 'track_list_screen.dart';

/// Search Screen
///
/// Allows users to search for tracks, albums, and artists
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            _buildSearchHeader(),

            // Content
            Expanded(
              child: Consumer<PlayerProvider>(
                builder: (context, player, child) {
                  if (player.isSearching) {
                    return _buildSearchingState();
                  }

                  if (player.searchError != null) {
                    return _buildErrorState(player.searchError!);
                  }

                  if (!_hasSearched) {
                    return _buildInitialState();
                  }

                  if (player.searchResults == null ||
                      (player.searchResults!.tracks.isEmpty &&
                          player.searchResults!.albums.isEmpty &&
                          player.searchResults!.artists.isEmpty)) {
                    return _buildNoResultsState();
                  }

                  return _buildSearchResults(player.searchResults!);
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

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'SEARCH',
                style: TextStyle(
                  fontFamily: 'Inconsolata',
                  fontSize: 14,
                  letterSpacing: 3,
                  color: AppTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: const TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 14,
              color: AppTheme.text,
              letterSpacing: 1,
            ),
            decoration: InputDecoration(
              hintText: 'Search tracks, albums, artists...',
              hintStyle: const TextStyle(
                fontFamily: 'Inconsolata',
                fontSize: 12,
                color: AppTheme.textDim,
                letterSpacing: 1,
              ),
              prefixIcon: const Icon(
                Icons.search,
                size: 18,
                color: AppTheme.textDim,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, child) {
                  if (value.text.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _hasSearched = false;
                      });
                      final player = Provider.of<PlayerProvider>(
                        context,
                        listen: false,
                      );
                      player.clearSearch();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.textDim,
                      ),
                    ),
                  );
                },
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (query) {
              if (query.isNotEmpty) {
                setState(() {
                  _hasSearched = true;
                });
                final player = Provider.of<PlayerProvider>(
                  context,
                  listen: false,
                );
                player.search(query);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, color: AppTheme.textDim, size: 64),
          const SizedBox(height: 24),
          Text(
            'SEARCH',
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 16,
              letterSpacing: 4,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find your favorite music',
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 10,
              color: AppTheme.textDim,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingState() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const SkeletonLoader(height: 20, width: 200),
          const SizedBox(height: 24),
          const SkeletonLoader(height: 60, width: double.infinity),
          const SizedBox(height: 12),
          const SkeletonLoader(height: 60, width: double.infinity),
          const SizedBox(height: 12),
          const SkeletonLoader(height: 60, width: double.infinity),
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
              'Search failed',
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
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, color: AppTheme.textDim, size: 48),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 12,
              color: AppTheme.text,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different search term',
            style: TextStyle(fontSize: 10, color: AppTheme.textDim),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(SearchResults results) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tracks
          if (results.tracks.isNotEmpty) ...[
            _buildSectionTitle('TRACKS'),
            const SizedBox(height: 8),
            ...results.tracks.map((track) => TrackListTile(track: track)),
            const SizedBox(height: 24),
          ],

          // Albums
          if (results.albums.isNotEmpty) ...[
            _buildSectionTitle('ALBUMS'),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: results.albums.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _AlbumResultCard(album: results.albums[index]);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Artists
          if (results.artists.isNotEmpty) ...[
            _buildSectionTitle('ARTISTS'),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: results.artists.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  return _ArtistResultCard(artist: results.artists[index]);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inconsolata',
        fontSize: 9,
        letterSpacing: 3,
        color: AppTheme.textDim,
      ),
    );
  }
}

/// Album result card
class _AlbumResultCard extends StatelessWidget {
  final Album album;

  const _AlbumResultCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackListScreen(
              title: album.title,
              tracks: album.tracks ?? [],
              subtitle: album.artistName,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 160,
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
                  child: album.coverUrl != null && album.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: album.coverUrl!,
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
              album.title,
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
              album.artistName,
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

/// Artist result card
class _ArtistResultCard extends StatelessWidget {
  final Artist artist;

  const _ArtistResultCard({required this.artist});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border, width: 1),
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: artist.imageUrl != null && artist.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: artist.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.surface,
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.textDim,
                            size: 32,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.surface,
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.textDim,
                            size: 32,
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.surface,
                        child: const Icon(
                          Icons.person,
                          color: AppTheme.textDim,
                          size: 32,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            artist.name,
            style: const TextStyle(
              fontFamily: 'Inconsolata',
              fontSize: 10,
              color: AppTheme.text,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
