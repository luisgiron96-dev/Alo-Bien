class SocialLink {
  /// Icono PNG en assets/images (azul oscuro sobre fondo transparente).
  final String asset;
  final String label;
  final String url;
  const SocialLink(this.asset, this.label, this.url);

  bool get hasLink => Uri.tryParse(url)?.hasScheme ?? false;
}

class SocialLinks {
  // Telegram queda pendiente: pega el enlace entre las comillas (con https://)
  static const instagram =
      'https://www.instagram.com/alobienplataforma?knvt=MXN5eDFjdHl2ZXVmMw==';
  static const youtube = 'https://youtube.com/@alobienplataforma';
  static const facebook = 'https://www.facebook.com/share/1CK312NpCh/';
  static const tiktok =
      'https://www.tiktok.com/@alobienplataforma?_r=1&_t=ZS-9BXaJmAXl0W';
  static const telegram = '';

  static const all = <SocialLink>[
    SocialLink('assets/images/social_instagram.png', 'Instagram', instagram),
    SocialLink('assets/images/social_youtube.png', 'YouTube', youtube),
    SocialLink('assets/images/social_facebook.png', 'Facebook', facebook),
    SocialLink('assets/images/social_tiktok.png', 'TikTok', tiktok),
    SocialLink('assets/images/social_telegram.png', 'Telegram', telegram),
  ];
}