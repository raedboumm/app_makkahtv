import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';
import '../widgets/library_widgets.dart';

/// "مكتبة البرامج" — the channel's full YouTube catalog, same as the web
/// version's /library page: random / newest / trending / oldest + search.
/// (Playlists live in their own tab, "سلاسل البرامج", like the web's /series.)
class ProgramsLibraryScreen extends StatefulWidget {
  final VoidCallback? onOpenMenu;
  const ProgramsLibraryScreen({super.key, this.onOpenMenu});

  @override
  State<ProgramsLibraryScreen> createState() => _ProgramsLibraryScreenState();
}

enum _Sort { random, newest, trending, oldest }

const _sortLabels = {
  _Sort.random: 'عشوائي',
  _Sort.newest: 'الأحدث',
  _Sort.trending: 'الرائجة',
  _Sort.oldest: 'الأقدم',
};

const _pageSize = 24;

class _ProgramsLibraryScreenState extends State<ProgramsLibraryScreen> {
  // null = still loading (never show fake videos while waiting)
  List<YouTubeVideo>? _videos;
  bool _catalogFullyLoaded = false;
  _Sort _sort = _Sort.random;
  int _visibleCount = _pageSize;
  String _query = '';

  // Random order that's new on every app launch but stays put while the
  // screen lives: videos arriving later (page by page) are appended
  // shuffled, so visible cards never jump. Same as the web's useRandomOrder.
  final List<String> _randomOrder = [];
  final _rng = Random();

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

  // Network is sometimes not ready right after launch: retry quietly a few
  // times (keeping the skeleton) before showing the "couldn't load" message.
  Future<void> _loadCatalog({int attempt = 0}) async {
    final data = await YouTubeService.fetchAllChannelVideos(onProgress: _onCatalogProgress);
    if (!mounted) return;
    if (data.isEmpty && YouTubeService.isConfigured && attempt < 2) {
      await Future.delayed(Duration(seconds: 3 * (attempt + 1)));
      if (mounted) _loadCatalog(attempt: attempt + 1);
      return;
    }
    setState(() {
      _videos = data;
      _catalogFullyLoaded = true;
    });
  }

  void _retryCatalog() {
    setState(() {
      _videos = null;
      _catalogFullyLoaded = false;
    });
    _loadCatalog();
  }

  void _setSort(_Sort s) {
    if (s == _sort) return;
    setState(() {
      _sort = s;
      _visibleCount = _pageSize;
    });
  }

  void _setQuery(String v) {
    setState(() {
      _query = v.trim().toLowerCase();
      _visibleCount = _pageSize;
    });
  }

  bool _matches(String title) => _query.isEmpty || title.toLowerCase().contains(_query);

  List<YouTubeVideo> _randomized(List<YouTubeVideo> all) {
    final known = _randomOrder.toSet();
    final fresh = all.where((v) => !known.contains(v.id)).map((v) => v.id).toList()
      ..shuffle(_rng);
    _randomOrder.addAll(fresh);
    final byId = {for (final v in all) v.id: v};
    return [for (final id in _randomOrder) ?byId[id]];
  }

  List<YouTubeVideo> get _sortedFilteredVideos {
    final all = _videos ?? [];
    final list = (_sort == _Sort.random ? _randomized(all) : List.of(all))
        .where((v) => _matches(v.title))
        .toList();
    switch (_sort) {
      case _Sort.newest:
        list.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      case _Sort.oldest:
        list.sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
      case _Sort.trending:
        list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      case _Sort.random:
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
        LibraryHeader(
          title: 'مكتبة البرامج',
          icon: Icons.video_library_rounded,
          hint: 'ابحث عن فيديو...',
          controller: _searchCtrl,
          query: _query,
          onQueryChanged: _setQuery,
          onOpenMenu: widget.onOpenMenu,
        ),
        _buildFilters(isDark),
        Expanded(child: _buildBody()),
      ],
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

  Widget _buildBody() {
    if (!YouTubeService.isConfigured) {
      return const LibraryMessage('لم يتم إعداد مفتاح YouTube API.');
    }

    final videos = _videos;
    if (videos == null) return const LibrarySkeletonGrid();
    if (videos.isEmpty) {
      return LibraryMessage('تعذر تحميل الفيديوهات الآن. تحقق من الاتصال ثم أعد المحاولة.',
          onRetry: _retryCatalog);
    }
    final filtered = _sortedFilteredVideos;
    if (filtered.isEmpty) return const LibraryMessage('لا توجد نتائج مطابقة لبحثك.');

    return LibraryVideoGrid(
      videos: filtered.take(_visibleCount).toList(),
      queue: filtered,
      queueTitle: 'مكتبة البرامج · ${_sortLabels[_sort]}',
      hasMore: _visibleCount < filtered.length,
      onLoadMore: () => setState(() => _visibleCount += _pageSize),
      loadingMore: !_catalogFullyLoaded,
    );
  }
}
