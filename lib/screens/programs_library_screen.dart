import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';
import '../widgets/video_card.dart';

/// "مكتبة البرامج" — the channel's full YouTube catalog, same as the web
/// version's /library page: newest / trending / oldest / playlists + search.
class ProgramsLibraryScreen extends StatefulWidget {
  const ProgramsLibraryScreen({super.key});

  @override
  State<ProgramsLibraryScreen> createState() => _ProgramsLibraryScreenState();
}

enum _Sort { newest, trending, oldest, playlists }

const _sortLabels = {
  _Sort.newest: 'الأحدث',
  _Sort.trending: 'الرائجة',
  _Sort.oldest: 'الأقدم',
  _Sort.playlists: 'قوائم التشغيل',
};

const _pageSize = 24;

class _ProgramsLibraryScreenState extends State<ProgramsLibraryScreen> {
  // null = still loading (never show fake videos while waiting)
  List<YouTubeVideo>? _videos;
  bool _catalogFullyLoaded = false;
  _Sort _sort = _Sort.newest;
  int _visibleCount = _pageSize;
  String _query = '';

  List<YouTubePlaylist>? _playlists;
  YouTubePlaylist? _openPlaylist;
  List<YouTubeVideo>? _playlistVideos;
  int _playlistVisibleCount = _pageSize;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    YouTubeService.removeChannelListener(_onCatalogProgress);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onCatalogProgress(List<YouTubeVideo> partial) {
    if (mounted) setState(() => _videos = partial);
  }

  Future<void> _loadCatalog() async {
    final data = await YouTubeService.fetchAllChannelVideos(onProgress: _onCatalogProgress);
    if (!mounted) return;
    setState(() {
      _videos = data;
      _catalogFullyLoaded = true;
    });
  }

  Future<void> _loadPlaylists() async {
    final data = await YouTubeService.fetchChannelPlaylists();
    if (mounted) setState(() => _playlists = data);
  }

  void _setSort(_Sort s) {
    if (s == _sort) return;
    setState(() {
      _sort = s;
      _visibleCount = _pageSize;
      _openPlaylist = null;
      _playlistVideos = null;
    });
    if (s == _Sort.playlists && _playlists == null) _loadPlaylists();
  }

  void _setQuery(String v) {
    setState(() {
      _query = v.trim().toLowerCase();
      _visibleCount = _pageSize;
      _playlistVisibleCount = _pageSize;
    });
  }

  Future<void> _openPlaylistTap(YouTubePlaylist p) async {
    setState(() {
      _openPlaylist = p;
      _playlistVideos = null;
      _playlistVisibleCount = _pageSize;
    });
    final videos = await YouTubeService.fetchPlaylistVideos(p.id);
    if (mounted && _openPlaylist?.id == p.id) setState(() => _playlistVideos = videos);
  }

  bool _matches(String title) => _query.isEmpty || title.toLowerCase().contains(_query);

  List<YouTubeVideo> get _sortedFilteredVideos {
    final list = (_videos ?? []).where((v) => _matches(v.title)).toList();
    switch (_sort) {
      case _Sort.newest:
        list.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      case _Sort.oldest:
        list.sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
      case _Sort.trending:
        list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      case _Sort.playlists:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        _buildHeader(isDark),
        _buildFilters(isDark),
        Expanded(child: _buildBody(isDark)),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white54 : AppColors.lightTextSub;
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.video_library_rounded, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Text('مكتبة البرامج',
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            onChanged: _setQuery,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ابحث عن فيديو...',
              hintStyle: TextStyle(color: subColor, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close_rounded, color: subColor, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _setQuery('');
                      },
                    ),
              isDense: true,
              filled: true,
              fillColor: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppColors.gold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: _Sort.values.map((s) {
          final selected = s == _sort;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(_sortLabels[s]!),
              selected: selected,
              onSelected: (_) => _setSort(s),
              showCheckmark: false,
              selectedColor: AppColors.gold,
              backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.lightSurface,
              side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
              labelStyle: TextStyle(
                color: selected
                    ? Colors.black
                    : (isDark ? Colors.white70 : AppColors.lightTextSub),
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (!YouTubeService.isConfigured) {
      return const _Message('لم يتم إعداد مفتاح YouTube API.');
    }

    if (_sort == _Sort.playlists) {
      final open = _openPlaylist;
      if (open != null) return _buildPlaylistVideos(open, isDark);

      final playlists = _playlists;
      if (playlists == null) return const _SkeletonGrid(count: 8);
      if (playlists.isEmpty) {
        return const _Message('تعذر تحميل قوائم التشغيل الآن، حاول مرة أخرى لاحقًا.');
      }
      final filtered = playlists.where((p) => _matches(p.title)).toList();
      if (filtered.isEmpty) return const _Message('لا توجد نتائج مطابقة لبحثك.');
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
        gridDelegate: _gridDelegate,
        itemCount: filtered.length,
        itemBuilder: (_, i) =>
            PlaylistCard(playlist: filtered[i], onTap: () => _openPlaylistTap(filtered[i])),
      );
    }

    final videos = _videos;
    if (videos == null) return const _SkeletonGrid();
    if (videos.isEmpty) {
      return const _Message('تعذر تحميل الفيديوهات الآن، حاول مرة أخرى لاحقًا.');
    }
    final filtered = _sortedFilteredVideos;
    if (filtered.isEmpty) return const _Message('لا توجد نتائج مطابقة لبحثك.');

    return _VideoGrid(
      videos: filtered.take(_visibleCount).toList(),
      hasMore: _visibleCount < filtered.length,
      onLoadMore: () => setState(() => _visibleCount += _pageSize),
      loadingMore: !_catalogFullyLoaded,
    );
  }

  Widget _buildPlaylistVideos(YouTubePlaylist playlist, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final videos = _playlistVideos;

    Widget content;
    if (videos == null) {
      content = const _SkeletonGrid(count: 8);
    } else if (videos.isEmpty) {
      content = const _Message('لا توجد فيديوهات في قائمة التشغيل هذه.');
    } else {
      final filtered = videos.where((v) => _matches(v.title)).toList();
      content = filtered.isEmpty
          ? const _Message('لا توجد نتائج مطابقة لبحثك في هذه القائمة.')
          : _VideoGrid(
              videos: filtered.take(_playlistVisibleCount).toList(),
              hasMore: _playlistVisibleCount < filtered.length,
              onLoadMore: () => setState(() => _playlistVisibleCount += _pageSize),
            );
    }

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() {
            _openPlaylist = null;
            _playlistVideos = null;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.arrow_forward_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    playlist.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  childAspectRatio: 0.92,
  crossAxisSpacing: 10,
  mainAxisSpacing: 10,
);

class _VideoGrid extends StatelessWidget {
  final List<YouTubeVideo> videos;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final bool loadingMore;
  const _VideoGrid({
    required this.videos,
    required this.hasMore,
    required this.onLoadMore,
    this.loadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          sliver: SliverGrid(
            gridDelegate: _gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (_, i) => VideoCard(video: videos[i]),
              childCount: videos.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
            child: Column(
              children: [
                if (loadingMore)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                        ),
                        const SizedBox(width: 8),
                        Text('جاري تحميل المزيد من الفيديوهات...',
                            style: TextStyle(
                                color: isDark ? Colors.white54 : AppColors.lightTextSub,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                if (hasMore)
                  OutlinedButton(
                    onPressed: onLoadMore,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    ),
                    child: const Text('تحميل المزيد'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  final int count;
  const _SkeletonGrid({this.count = 12});

  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: _gridDelegate,
        itemCount: count,
        itemBuilder: (_, i) => const VideoCardSkeleton(),
      );
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white54 : AppColors.lightTextSub, fontSize: 14),
        ),
      ),
    );
  }
}
