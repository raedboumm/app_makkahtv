import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app_theme.dart';
import '../data/static_data.dart';
import '../models/program.dart';
import 'program_detail_screen.dart';

class ProgramsTab extends StatelessWidget {
  const ProgramsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final programs = StaticData.programs;
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        _buildHeader(isDark, context),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: programs.length,
            itemBuilder: (_, i) => _ProgramGridCard(program: programs[i], isDark: isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark, BuildContext context) {
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.tv_rounded, color: AppColors.gold, size: 22),
          const SizedBox(width: 10),
          Text('البرامج',
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.search_rounded,
                color: isDark ? Colors.white70 : AppColors.lightTextSub),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ProgramGridCard extends StatelessWidget {
  final Program program;
  final bool isDark;
  const _ProgramGridCard({required this.program, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProgramDetailScreen(program: program)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
          boxShadow: isDark
              ? []
              : [BoxShadow(color: AppColors.gold.withValues(alpha: 0.08), blurRadius: 8)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (program.localImage != null)
                Image.asset(
                  program.localImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, _) => program.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: program.imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (ctx, e, s) => _placeholder())
                      : _placeholder(),
                )
              else if (program.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: program.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (ctx, e, s) => _placeholder(),
                )
              else
                _placeholder(),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.88)],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.nameAr,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (program.scheduleTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  color: AppColors.gold, size: 11),
                              const SizedBox(width: 3),
                              Text(program.scheduleTime!,
                                  style: const TextStyle(color: AppColors.gold, fontSize: 10)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkSurface2, AppColors.darkSurface],
          ),
        ),
        child: const Center(child: Icon(Icons.tv_rounded, color: AppColors.gold, size: 48)),
      );
}