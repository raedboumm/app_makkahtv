import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';
import 'frequency_strip.dart';

/// One entry of the app menu — same items as the web header's menu.
class MenuItemData {
  final IconData icon;
  final String label;
  const MenuItemData(this.icon, this.label);
}

const appMenuItems = [
  MenuItemData(Icons.home_rounded, 'الرئيسية'),
  MenuItemData(Icons.video_library_rounded, 'مكتبة البرامج'),
  MenuItemData(Icons.layers_rounded, 'سلاسل البرامج'),
];

/// Side menu opened by the ☰ toggle (the web's mobile menu): navigation,
/// dark/light toggle and the channel's social accounts.
class MainDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const MainDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  static const _socials = [
    (FontAwesomeIcons.facebook, 'https://www.facebook.com/MakkahTV'),
    (FontAwesomeIcons.xTwitter, 'https://x.com/MakkahTV'),
    (FontAwesomeIcons.youtube, 'https://www.youtube.com/MakkahTV'),
    (FontAwesomeIcons.instagram, 'https://www.instagram.com/makkahtv/'),
    (FontAwesomeIcons.tiktok, 'https://www.tiktok.com/@makkahtv.tv'),
  ];

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white54 : AppColors.lightTextSub;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                children: [
                  for (var i = 0; i < appMenuItems.length; i++)
                    _navItem(
                      icon: appMenuItems[i].icon,
                      label: appMenuItems[i].label,
                      isSelected: currentIndex == i,
                      textColor: textColor,
                      subColor: subColor,
                      onTap: () {
                        Navigator.pop(context);
                        onNavigate(i);
                      },
                    ),
                  const SizedBox(height: 8),
                  // ── ترددات البث — same box style as the selected menu item ──
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.satellite_alt_rounded,
                                color: AppColors.gold, size: 20),
                            const SizedBox(width: 10),
                            Text('ترددات البث الفضائي',
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final (label, value) in FrequencyStrip.rows)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(label,
                                    style: TextStyle(color: subColor, fontSize: 12)),
                                const Spacer(),
                                Text(value,
                                    style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(
                    indent: 16,
                    endIndent: 16,
                    color: Color(0x33D4AF37),
                  ),

                  // ── Social, right under the menu items ──
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final (icon, url) in _socials)
                          InkWell(
                            onTap: () => _launch(url),
                            customBorder: const CircleBorder(),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.gold.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.35),
                                ),
                              ),
                              child: FaIcon(icon, color: textColor, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                '© ${DateTime.now().year} قناة مكة الفضائية',
                style: TextStyle(color: subColor, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
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
          // Close toggle
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              tooltip: 'إغلاق القائمة',
              icon: Icon(
                Icons.close_rounded,
                color: isDark ? Colors.white70 : AppColors.lightText,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Image.asset(
            'assets/images/makkah-logo.png',
            height: 90,
            color: isDark ? Colors.white : AppColors.lightText,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (ctx, e, _) => Icon(
              Icons.mosque_rounded,
              size: 80,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}
