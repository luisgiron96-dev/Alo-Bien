import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../about/about_screen.dart';
import '../creator/creator_dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/web_page_screen.dart';

/// Pestaña "Más": agrupa el resto de secciones de la app y del sitio.
class MoreScreen extends StatelessWidget {
  final UserProfile profile;
  const MoreScreen({super.key, required this.profile});

  void _web(BuildContext context, Section s) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WebPageScreen(title: s.label, uri: s.uri),
    ));
  }

  void _page(BuildContext context, String title, Widget body) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(appBar: AppBar(title: Text(title)), body: body),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (profile.isCreator) ...[
          const _Header('Creador'),
          _Tile(
            icon: Icons.dashboard_rounded,
            title: 'Panel de creador',
            subtitle: 'Subir y administrar contenido',
            onTap: () =>
                _page(context, 'Panel de creador', const CreatorDashboardScreen()),
          ),
        ],
        const _Header('Mi cuenta'),
        _Tile(
          icon: Icons.person_rounded,
          title: 'Mi perfil',
          subtitle: profile.displayName,
          onTap: () =>
              _page(context, 'Mi perfil', ProfileScreen(profile: profile)),
        ),
        _Tile(
          icon: Icons.manage_accounts_rounded,
          title: 'Mi cuenta del sitio',
          subtitle: 'Ingresa a tu cuenta en alobienplataforma.com',
          onTap: () => _web(context, AppConfig.tabs[4]),
        ),
        _Tile(
          icon: Icons.shopping_bag_rounded,
          title: 'Carrito',
          subtitle: 'Tus compras en la tienda',
          onTap: () => _web(context, AppConfig.carrito),
        ),
        const _Header('ALO BIEN'),
        _Tile(
          icon: Icons.play_circle_rounded,
          title: 'Contenido del sitio',
          subtitle: 'Panel exclusivo de la plataforma',
          onTap: () => _web(context, AppConfig.tabs[1]),
        ),
        _Tile(
          icon: Icons.info_rounded,
          title: 'Nosotros',
          subtitle: 'Quiénes somos',
          onTap: () => _page(context, 'Nosotros', const AboutScreen()),
        ),
        _Tile(
          icon: Icons.mail_rounded,
          title: 'Contacto',
          subtitle: 'Escríbenos o llámanos',
          onTap: () => _web(context, AppConfig.extra[1]),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AloColors.lavender)),
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(icon, color: AloColors.lavender),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}