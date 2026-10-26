import 'package:flutter/material.dart';

/// Sección de la app = pestaña inferior + ruta del sitio.
/// TODO: confirmar las rutas reales del sitio (son supuestos).
class Section {
  final String label;
  final IconData icon;
  final String path;
  const Section(this.label, this.icon, this.path);
  Uri get uri => Uri.https(AppConfig.host, path);
}

class AppConfig {
  static const host = 'alobienplataforma.com';

  /// Hosts adicionales que deben abrirse dentro de la app
  /// (pasarela de pagos, login social, etc.). TODO: definir con el cliente.
  static const extraInternalHosts = <String>[];

  /// 5 pestañas inferiores.
  static const tabs = <Section>[
    Section('Inicio', Icons.home_rounded, '/'),
    Section('Contenido', Icons.play_circle_rounded, '/contenido/'),
    Section('Comunidad', Icons.groups_rounded, '/comunidad/'),
    Section('Tienda', Icons.shopping_cart_rounded, '/tienda/'),
    Section('Mi cuenta', Icons.person_rounded, '/mi-cuenta/'),
  ];

  /// Menú superior (fuera de la barra inferior).
  static const extra = <Section>[
    Section('Nosotros', Icons.info_rounded, '/nosotros/'),
    Section('Contacto', Icons.mail_rounded, '/contacto/'),
  ];

  /// Temas FCM a los que se suscribe el dispositivo. El sitio envía a estos temas.
  static const pushTopics = ['videos', 'contenido', 'novedades', 'comunidad'];

  static bool isInternal(Uri u) =>
      u.host == host ||
      u.host == 'www.$host' ||
      extraInternalHosts.contains(u.host);

  /// Valida que un deep link de push apunte al propio sitio (seguridad).
  static Uri? safeLink(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final u = Uri.tryParse(raw);
    if (u == null || u.scheme != 'https' || !isInternal(u)) return null;
    return u;
  }

  /// Pestaña que corresponde a una URL (o null si ninguna).
  static int? tabFor(Uri u) {
    for (var i = tabs.length - 1; i > 0; i--) {
      if (u.path.startsWith(tabs[i].path)) return i;
    }
    return null;
  }
}