import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/program.dart';
import '../app_theme.dart';

class ProgramCard extends StatelessWidget {
  final Program program;
  final VoidCallback? onTap;
  final double? cardWidth;

  const ProgramCard({super.key, required this.program, this.onTap, this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth ?? 130,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              if (program.localImage != null)
                Image.asset(
                  program.localImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, _) => _placeholder(),
                )
              else if (program.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: program.imageUrl!,
                  height: 200,
                  width: double.infinity,
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
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        program.nameAr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                      if (program.scheduleTime != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  color: AppColors.gold, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                program.scheduleTime!,
                                style: const TextStyle(
                                    color: AppColors.gold, fontSize: 9),
                              ),
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

  Widget _placeholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: AppColors.darkSurface2,
      child: const Center(
        child: Icon(Icons.tv_rounded, color: AppColors.gold, size: 36),
      ),
    );
  }
}
