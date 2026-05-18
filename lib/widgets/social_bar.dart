import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialBar extends StatelessWidget {
  const SocialBar({super.key});

  static const List<_Social> _socials = [
    _Social(icon: FontAwesomeIcons.facebook, url: 'https://www.facebook.com/makkahtv', color: Colors.white),
    _Social(icon: FontAwesomeIcons.xTwitter, url: 'https://twitter.com/makkahtv', color: Colors.white),
    _Social(icon: FontAwesomeIcons.youtube, url: 'https://www.youtube.com/makkahtv', color: Colors.white),
    _Social(icon: FontAwesomeIcons.instagram, url: 'https://www.instagram.com/makkahtv', color: Colors.white),
    _Social(icon: FontAwesomeIcons.tiktok, url: 'https://www.tiktok.com/@makkahtv.tv', color: Colors.white),
  ];

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _socials
          .map((s) => GestureDetector(
                onTap: () => _launch(s.url),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: FaIcon(s.icon, color: s.color, size: 14),
                ),
              ))
          .toList(),
    );
  }
}

class _Social {
  final IconData icon;
  final String url;
  final Color color;
  const _Social({required this.icon, required this.url, required this.color});
}
