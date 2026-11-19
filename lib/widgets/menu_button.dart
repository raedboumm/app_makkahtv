import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Hamburger toggle that opens the side menu (like the web header's ☰).
class MenuButton extends StatelessWidget {
  final VoidCallback onPressed;
  const MenuButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'القائمة',
      icon: const Icon(Icons.menu_rounded, color: AppColors.gold, size: 28),
      onPressed: onPressed,
    );
  }
}
