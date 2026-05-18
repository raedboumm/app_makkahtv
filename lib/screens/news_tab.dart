import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app_theme.dart';
import '../data/static_data.dart';
import '../models/article.dart';
import 'news_detail_screen.dart';

class NewsTab extends StatefulWidget {
  const NewsTab({super.key});
  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  String _selected = 'الكل';
  static const List<String> _categories = ['الكل', 'أخبار', 'حج وعمرة', 'أخبار القناة'];

  List<Article> get _filtered {
    if (_selected == 'الكل') return StaticData.articles;
    return StaticData.articles.where((a) => a.category == _selected).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        Container(
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.article_rounded, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Text('الأخبار',
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        _buildCategoryBar(isDark),
        Expanded(
          child: _filtered.isEmpty
              ? Center(child: Text('لا توجد أخبار', style: TextStyle(color: isDark ? Colors.white54 : AppColors.lightTextSub)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _ArticleCard(article: _filtered[i], isDark: isDark),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryBar(bool isDark) {
    final barBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    return Container(
      color: barBg,
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isActive = cat == _selected;
          return GestureDetector(
            onTap: () => setState(() => _selected = cat),
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.gold
                    : (isDark ? AppColors.darkSurface3 : AppColors.lightSurface3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isActive
                      ? AppColors.darkBg
                      : (isDark ? Colors.white70 : AppColors.lightTextSub),
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;
  final bool isDark;
  const _ArticleCard({required this.article, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? Colors.white10 : const Color(0x22D4AF37);
    final titleColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white54 : AppColors.lightTextSub;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : [BoxShadow(color: AppColors.gold.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: SizedBox(
              width: 100,
              height: 100,
              child: article.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: article.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, e, s) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.category != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(article.category!,
                          style: const TextStyle(color: AppColors.gold, fontSize: 10)),
                    ),
                  Text(article.title,
                      style: TextStyle(color: titleColor, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (article.excerpt != null) ...[
                    const SizedBox(height: 4),
                    Text(article.excerpt!,
                        style: TextStyle(color: subColor, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (article.publishedAt != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, color: isDark ? Colors.white38 : AppColors.lightTextSub, size: 11),
                        const SizedBox(width: 4),
                        Text(
                          '${article.publishedAt!.day}/${article.publishedAt!.month}/${article.publishedAt!.year}',
                          style: TextStyle(color: isDark ? Colors.white38 : AppColors.lightTextSub, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: AppColors.darkSurface2,
        child: const Center(child: Icon(Icons.article_rounded, color: AppColors.gold, size: 30)),
      );
}