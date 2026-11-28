import 'package:flutter/material.dart';

/// Sección de la app = icono + ruta del sitio.
/// Rutas confirmadas en alobienplataforma.com (WordPress).
class Section {
  final String label;
  final IconData icon;
  final String path;
  const Section(this.label, this.icon, this.path);
  Uri get uri => Uri.https(AppConfig.host, path);
}

class AppConfig {
  static const host = 'alobienplataforma.com';

  /// Subdominios del propio sitio (la red social "Únete a ALO BIEN").
  static const siteHosts = <String>['social.alobienplataforma.com'];

  /// Pasarelas de pago que deben abrirse DENTRO de la app para no sacar al
  /// usuario de la compra. Cuando definas la pasarela real del sitio
  /// (WooCommerce / membresías), confirma que su dirección esté en esta lista.
  static const paymentHosts = <String>[
    'checkout.wompi.co',
    'checkout.payulatam.com',
    'gateway.payulatam.com',
    'checkout.epayco.co',
    'secure.epayco.co',
    'www.mercadopago.com.co',
    'www.paypal.com',
  ];

  /// Secciones del sitio. El ORDEN importa: otras pantallas usan
  /// tabs[2] (Comunidad), tabs[3] (Tienda) y tabs[4] (Mi cuenta).
  static const tabs = <Section>[
    Section('Inicio', Icons.home_rounded, '/'),
    Section('Contenido', Icons.play_circle_rounded, '/panel-exclusivo/'),
    Section('Comunidad', Icons.groups_rounded, '/members/'),
    Section('Tienda', Icons.shopping_cart_rounded, '/tienda/'),
    Section('Mi cuenta', Icons.person_rounded, '/account/'),
  ];

  /// Otras secciones del menú del sitio.
  static const extra = <Section>[
    Section('Nosotros', Icons.info_rounded, '/quienes-somos/'),
    Section('Contacto', Icons.mail_rounded, '/contacto/'),
  ];

  static const carrito =
      Section('Carrito', Icons.shopping_bag_rounded, '/carrito/');

  /// Temas FCM a los que se suscribe el dispositivo. El sitio envía a estos temas.
  static const pushTopics = ['videos', 'contenido', 'novedades', 'comunidad'];

  /// ¿Es una dirección del propio sitio?
  static bool isSiteHost(Uri u) =>
      u.host == host || u.host == 'www.$host' || siteHosts.contains(u.host);

  /// ¿Debe abrirse dentro de la app? (sitio + pasarelas de pago)
  static bool isInternal(Uri u) => isSiteHost(u) || paymentHosts.contains(u.host);

  /// Valida que un deep link de push apunte al propio sitio (seguridad).
  static Uri? safeLink(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final u = Uri.tryParse(raw);
    if (u == null || u.scheme != 'https' || !isSiteHost(u)) return null;
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