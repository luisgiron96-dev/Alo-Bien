class SocialLink {
  /// Icono PNG en assets/images (azul oscuro sobre fondo transparente).
  final String asset;
  final String label;
  final String url;
  const SocialLink(this.asset, this.label, this.url);

  bool get hasLink => Uri.tryParse(url)?.hasScheme ?? false;
}

class SocialLinks {
  // TODO: pega los enlaces reales entre las comillas (con https://)
  static const instagram = '';
  static const youtube = '';
  static const facebook = '';
  static const tiktok = '';
  static const telegram = '';

  static const all = <SocialLink>[
    SocialLink('assets/images/social_instagram.png', 'Instagram', instagram),
    SocialLink('assets/images/social_youtube.png', 'YouTube', youtube),
    SocialLink('assets/images/social_facebook.png', 'Facebook', facebook),
    SocialLink('assets/images/social_tiktok.png', 'TikTok', tiktok),
    SocialLink('assets/images/social_telegram.png', 'Telegram', telegram),
  ];
}