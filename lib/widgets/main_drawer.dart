import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';

class MainDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final VoidCallback? onScrollToSchedule;
  final VoidCallback? onScrollToPrograms;
  final VoidCallback? onScrollToInterviews;
  final VoidCallback? onScrollToSocial;

  const MainDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    this.onScrollToSchedule,
    this.onScrollToPrograms,
    this.onScrollToInterviews,
    this.onScrollToSocial,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white54 : AppColors.lightTextSub;
    final dividerColor = isDark ? Colors.white12 : const Color(0x22D4AF37);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: [
                  // ── Tab navigation ──────────────────────────────────────
                  _navItem(
                    context,
                    icon: Icons.home_rounded,
                    label: 'الرئيسية',
                    isSelected: currentIndex == 0,
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () { Navigator.pop(context); onNavigate(0); },
                  ),
                  _navItem(
                    context,
                    icon: Icons.live_tv_rounded,
                    label: 'مباشر',
                    isSelected: currentIndex == 1,
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () { Navigator.pop(context); onNavigate(1); },
                  ),

                  _sectionItem(
                    context,
                    icon: Icons.schedule_rounded,
                    label: 'البث اليومي',
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () { Navigator.pop(context); onScrollToSchedule?.call(); },
                  ),
                  _sectionItem(
                    context,
                    icon: Icons.tv_rounded,
                    label: 'أحدث البرامج',
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () { Navigator.pop(context); onScrollToPrograms?.call(); },
                  ),
                  _sectionItem(
                    context,
                    icon: Icons.satellite_alt_rounded,
                    label: 'ترددات القناة',
                    textColor: textColor,
                    subColor: subColor,
                    onTap: () { Navigator.pop(context); onScrollToInterviews?.call(); },
                  ),
                ],
              ),
            ),

            // ── تواصل معنا ───────────────────────────────────────────────
            _sectionItem(
              context,
              icon: Icons.people_alt_rounded,
              label: 'تواصل معنا',
              textColor: textColor,
              subColor: subColor,
              onTap: () { Navigator.pop(context); onScrollToSocial?.call(); },
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),


            // ── Theme toggle ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isDark ? 'الوضع الليلي' : 'الوضع النهاري',
                    style: TextStyle(color: textColor, fontSize: 13),
                  ),
                  const Spacer(),
                  Switch(
                    value: isDark,
                    onChanged: (_) => context.read<ThemeProvider>().toggle(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Text(
                    'info@makkahtv.tv',
                    style: TextStyle(color: subColor, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 قناة مكة الفضائية',
                    style: TextStyle(
                        color: isDark ? Colors.white24 : AppColors.lightTextSub,
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color textColor,
    required Color subColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? AppColors.gold : subColor),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.gold : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.gold.withValues(alpha: 0.12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _sectionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color textColor,
    required Color subColor,
    required VoidCallback onTap,
    EdgeInsets padding = const EdgeInsets.only(bottom: 4),
  }) {
    return Container(
      margin: padding,
      child: ListTile(
        leading: Icon(icon, color: subColor, size: 22),
        title: Text(label, style: TextStyle(color: textColor)),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [const Color(0xFF2E1A00), AppColors.darkSurface]
              : [AppColors.lightSurface3, AppColors.lightBg],
        ),
      ),
      child: Column(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              isDark ? Colors.white : AppColors.lightText,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/images/makkah-logo.png',
              height: 110,
              errorBuilder: (ctx, e, _) => Icon(
                Icons.mosque_rounded,
                size: 80,
                color: isDark ? Colors.white : AppColors.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
