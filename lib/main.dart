import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/youtube_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Clear any stale empty cache that may have been written before the API key
  // was configured (empty lists are now rejected, but old entries need purging).
  YouTubeService.clearCache();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MakkahTvApp(),
    ),
  );
}

class MakkahTvApp extends StatelessWidget {
  const MakkahTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'قناة مكة',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
  }
}
