import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

class FrequencyStrip extends StatelessWidget {
  const FrequencyStrip({super.key});

  static const rows = [
    ('القمر الصناعي', 'عربسات بدر'),
    ('التردد', '11398'),
    ('الاستقطاب', 'عمودي'),
    ('معدل الترميز', '27500'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppColors.lightText;
    final cardBg = isDark ? const Color(0xFF1E1A12) : Colors.white;
    final labelColor = isDark
        ? Colors.white60
        : AppColors.lightText.withValues(alpha: 0.55);
    final valueColor = isDark ? Colors.white : AppColors.lightText;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        // Title sits out toward the edge (start = right in RTL); the card keeps 16.
        padding: const EdgeInsetsDirectional.fromSTEB(4, 40, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section title (outside the box) ──
            // Inset like the other home section titles so they all align.
            Padding(
              padding: EdgeInsetsDirectional.zero,
              child: Row(
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      isDark ? Colors.white : AppColors.lightText,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/images/makkah-logo cicle.png',
                      height: 42,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 42),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ترددات البث الفضائي',
                    style: GoogleFonts.cairo(
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Single card with all rows ──
            Container(
              margin: const EdgeInsetsDirectional.only(start: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: List.generate(rows.length, (i) {
                  final (label, value) = rows[i];
                  final isLast = i == rows.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.cairo(
                                color: labelColor,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              value,
                              style: GoogleFonts.cairo(
                                color: valueColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.gold.withValues(alpha: 0.12),
                          indent: 16,
                          endIndent: 16,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
