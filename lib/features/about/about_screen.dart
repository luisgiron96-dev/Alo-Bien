import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Datos de contacto tomados de la página "Quiénes Somos" del sitio.
  static const phoneLabel = '+57 302 4660040';
  static final phoneUri = Uri.parse('tel:+573024660040');
  static const emailLabel = 'contacto@alobienplataforma.com';
  static final emailUri = Uri.parse('mailto:contacto@alobienplataforma.com');

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Quiénes somos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        const _TeamPhoto('assets/images/equipo1.jpg'),
        const _SectionTitle('¿Cómo lo hacemos?'),
        const _Para(
            'Somos un equipo de artistas creativos, capaces de solucionar tus problemas dentro de tu propuesta empresarial. Basamos nuestro conocimiento en el Arte, lo audiovisual, y los medios de comunicación. Combinamos todos estos factores junto al nuevo sistema digital.'),
        const _Para(
            'Manejamos tus redes sociales para que tengas la mejor difusión. Nuestro equipo profesional para llevar tu marca al siguiente nivel en el mundo digital.'),
        const _Para(
            'Plataforma de medios de comunicación Online, enfocada a difundir contenido educativo, artístico y de entretenimiento. También tiene como propósito la difusión de noticias a nivel nacional e internacional de carácter global.'),
        const SizedBox(height: 8),
        const Row(children: [
          _Stat(value: '14', label: 'integrantes'),
          SizedBox(width: 10),
          _Stat(value: '3', label: 'países'),
          SizedBox(width: 10),
          _Stat(value: '7', label: 'programas aliados'),
        ]),
        const SizedBox(height: 16),
        const _Para(
            'Con 14 integrantes y presencia en 3 países, ALO BIEN construye puentes entre artistas, creadores y audiencias. Nuestros 7 programas aliados garantizan una difusión real y efectiva de tu contenido.'),
        const _Para(
            'Están formados bajo estrictas normas del conocimiento artístico, comercial y de marketing digital, dejando a un lado los mitos que dañan la estructura de cualquier empresa o producto.'),
        const _TeamPhoto('assets/images/equipo2.jpg'),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AloColors.bgDeep,
            borderRadius: BorderRadius.circular(16),
            border: const Border(
                left: BorderSide(color: AloColors.violet, width: 4)),
          ),
          child: const Text(
            'Nuestra meta es lograr que cada quien tenga como único competidor a sí mismo, siendo cada día mejor de lo que fuimos ayer.',
            style: TextStyle(
                fontSize: 15, fontStyle: FontStyle.italic, height: 1.5),
          ),
        ),
        const _Para(
            'Como plataforma buscamos ser el medio confiable no solo para el público, sino también para los creadores de contenido y artistas que quieran hacer parte de este proyecto.'),
        const _SectionTitle('Únete a ALO BIEN'),
        const _Para(
            'Nuestra plataforma es el espacio donde el talento se encuentra con la oportunidad. Descubre cómo podemos impulsar tu proyecto artístico y llevarlo a nuevas audiencias.'),
        const _Para(
            'Sé parte de la gira de medios online de ALO BIEN y expande tu alcance digital. Contamos con el equipo y los canales para que tu mensaje llegue a las personas correctas en el momento indicado. Esta es tu plataforma. Bienvenido a ALO BIEN.'),
        const SizedBox(height: 12),
        const _SectionTitle('Contacto'),
        _ContactTile(
            icon: Icons.phone_rounded, text: phoneLabel, uri: phoneUri),
        _ContactTile(
            icon: Icons.mail_rounded, text: emailLabel, uri: emailUri),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(width: 48, height: 3, color: AloColors.violet),
        ]),
      );
}

class _Para extends StatelessWidget {
  final String text;
  const _Para(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(height: 1.55, color: Colors.white70)),
      );
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AloColors.bgDeep,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AloColors.lavender)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11)),
          ]),
        ),
      );
}

/// Muestra la foto si existe en assets/; si no, no ocupa espacio.
class _TeamPhoto extends StatelessWidget {
  final String asset;
  const _TeamPhoto(this.asset);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(asset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink()),
        ),
      );
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final Uri uri;
  const _ContactTile(
      {required this.icon, required this.text, required this.uri});
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AloColors.lavender),
        title: Text(text),
        onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
      );
}