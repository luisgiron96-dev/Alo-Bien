import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import 'web_page_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile profile;
  const ProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    // TODO: confirmar las rutas reales del sitio en config.dart
    final links = <Section>[
      const Section('Sitio ALO BIEN', Icons.language_rounded, '/'),
      AppConfig.tabs[2], // Comunidad
      AppConfig.tabs[3], // Tienda
    ];
    final initial = profile.displayName.characters.first.toUpperCase();
    final hasName = (profile.fullName ?? '').trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Center(
          child: CircleAvatar(
            radius: 38,
            backgroundColor: AloColors.violet,
            child: Text(initial,
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(profile.displayName,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        if (hasName) Center(child: Text(profile.email)),
        const SizedBox(height: 10),
        Center(
          child: Chip(
            avatar: Icon(
                profile.isCreator
                    ? Icons.auto_awesome_rounded
                    : Icons.person_rounded,
                size: 16),
            label: Text(profile.isCreator ? 'Creador de contenido' : 'Usuario'),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Sitio web',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        for (final s in links)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(s.icon, color: AloColors.lavender),
            title: Text(s.label),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => WebPageScreen(title: s.label, uri: s.uri),
            )),
          ),
        const Divider(height: 32),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.logout_rounded),
          title: const Text('Cerrar sesión'),
          onTap: AuthService.signOut,
        ),
      ],
    );
  }
}