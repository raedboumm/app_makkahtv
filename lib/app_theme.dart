import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';



class AppColors {
  // Shared
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE8C84C);
  static const Color goldDim = Color(0xFF9C7D1F);
  static const Color livePulse = Color(0xFFFF3B30);

  // Dark mode
  static const Color dark = Color(0xFF0D0D0D);        // kept for compat
  static const Color surface = Color(0xFF1A1A1A);     // kept for compat
  static const Color surfaceLight = Color(0xFF2A2A2A);// kept for compat
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurface2 = Color(0xFF252525);
  static const Color darkSurface3 = Color(0xFF2E2E2E);

  // Light mode
  static const Color lightBg = Color(0xFFF5F0E8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFFAF6ED);
  static const Color lightSurface3 = Color(0xFFEEE8D5);
  static const Color lightText = Color(0xFF1A1200);
  static const Color lightTextSub = Color(0xFF5A4A00);
}

// â”€â”€â”€ Theme factory â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AppTheme {
  // â”€â”€ Dark â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static ThemeData get darkTheme {
    final base = GoogleFonts.cairoTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall: TextStyle(color: Colors.white70, fontSize: 14),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 15),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 13),
        bodySmall: TextStyle(color: Colors.white54, fontSize: 12),
        labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
        surface: AppColors.darkSurface,
        onPrimary: AppColors.darkBg,
        onSecondary: AppColors.darkBg,
        onSurface: Colors.white,
      ),
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
            color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.darkSurface),
      dividerColor: Colors.white12,
      iconTheme: const IconThemeData(color: Colors.white70),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.gold : Colors.white38),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.goldDim : Colors.white24),
      ),
    );
  }

  // â”€â”€ Light â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static ThemeData get lightTheme {
    final base = GoogleFonts.cairoTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.bold, fontSize: 26),
        titleLarge: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall: TextStyle(color: AppColors.lightTextSub, fontSize: 14),
        bodyLarge: TextStyle(color: AppColors.lightText, fontSize: 15),
        bodyMedium: TextStyle(color: AppColors.lightTextSub, fontSize: 13),
        bodySmall: TextStyle(color: AppColors.lightTextSub, fontSize: 12),
        labelLarge: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
        surface: AppColors.lightSurface,
        onPrimary: AppColors.lightText,
        onSecondary: AppColors.lightText,
        onSurface: AppColors.lightText,
      ),
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
            color: AppColors.lightText, fontSize: 19, fontWeight: FontWeight.bold),
        iconTheme: const IconThemeData(color: AppColors.lightText),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.lightTextSub,
        type: BottomNavigationBarType.fixed,
        elevation: 4,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shadowColor: Color(0x22D4AF37),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.lightSurface),
      dividerColor: const Color(0x22D4AF37),
      iconTheme: const IconThemeData(color: AppColors.lightTextSub),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.gold : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.goldDim : const Color(0xFFE0D5C0)),
      ),
    );
  }
}

// â”€â”€â”€ Theme provider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';
  bool _isDark = true;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
  }
}
