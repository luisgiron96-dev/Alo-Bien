import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/social_links.dart';
import '../../core/theme.dart';
import '../../models/content_item.dart';
import '../../services/content_repository.dart';
import '../../widgets/alo_logo.dart';
import '../../widgets/content_card.dart';
import '../../widgets/content_detail_sheet.dart';
import '../../widgets/cover_image.dart';
import '../../widgets/section_header.dart';
import '../profile/web_page_screen.dart';
import 'content_list_screen.dart';

// Colores medidos del diseño de referencia.
const _cyan = Color(0xFF75DAF9);
const _lightText = Color(0xFFC6DCF9);
const _glow = Color(0xFF31ABE1);

void _openWeb(BuildContext context, String title, Uri uri) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => WebPageScreen(title: title, uri: uri),
  ));
}

void _openList(BuildContext context, String title, List<ContentItem> items) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => ContentListScreen(title: title, items: items),
  ));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ContentItem>>(
      stream: ContentRepository.watchPublished(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No pudimos cargar el contenido. Revisa tu conexión.',
                  textAlign: TextAlign.center),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        final featured = items.where((i) => i.featured).toList();
        final hero = featured.isNotEmpty
            ? featured.first
            : (items.isNotEmpty ? items.first : null);
        final rows = <(String, List<ContentItem>)>[
          ('Novedades', items.where((i) => i.isNew).toList()),
          for (final t in ContentType.values)
            (t.rowTitle, items.where((i) => i.type == t).toList()),
        ].where((r) => r.$2.isNotEmpty).toList();

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            if (hero != null) _Hero(item: hero),
            const _BrandBanner(),
            SectionHeader(
              title: 'Contenido destacado',
              moreLabel: 'Ver más',
              onMore: items.isEmpty
                  ? null
                  : () => _openList(context, 'Contenido destacado',
                      featured.isNotEmpty ? featured : items),
            ),
            _FeaturedRow(
              items: featured,
              // El play del banner abre la ventana de reproducción del
              // contenido principal (el mismo del héroe de arriba).
              onPlayPromo: () {
                if (hero != null) {
                  showContentDetail(context, hero);
                } else {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(
                        content: Text('Aún no hay contenido para reproducir.')));
                }
              },
            ),
            SectionHeader(
              title: 'Productos ALO BIEN',
              moreLabel: 'Ver todos',
              onMore: () =>
                  _openWeb(context, 'Tienda', AppConfig.tabs[3].uri),
            ),
            const _Products(),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Aún no hay contenido publicado.')),
              ),
            for (final r in rows) ...[
              SectionHeader(
                title: r.$1,
                moreLabel: 'Ver más',
                onMore: () => _openList(context, r.$1, r.$2),
              ),
              _ContentRow(items: r.$2),
            ],
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------- Hero

class _Hero extends StatelessWidget {
  final ContentItem item;
  const _Hero({required this.item});

  @override
  Widget build(BuildContext context) {
    final label = (item.category != null && item.category!.isNotEmpty)
        ? item.category!
        : item.type.label;
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CoverImage(item: item, showIcon: false),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AloColors.bg],
                begin: Alignment.center,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => showContentDetail(context, item),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                      color: Color(0xE6FFFFFF), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded,
                      size: 42, color: AloColors.bgDeep),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  if (item.isNew) ...[const NewBadge(), const SizedBox(width: 8)],
                  Flexible(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AloColors.lavender,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w700)),
                if (item.description != null &&
                    item.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _lightText)),
                ],
                const SizedBox(height: 14),
                _GlowButton(
                  label: 'Ver detalles',
                  icon: Icons.info_outline_rounded,
                  onTap: () => showContentDetail(context, item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GlowButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF3A6DB0), Color(0xFF2B4F86)]),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x44FFFFFF)),
            boxShadow: const [
              BoxShadow(color: Color(0x554C8DFF), blurRadius: 18)
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 20),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      );
}

// -------------------------------------------------------- Banner de marca

class _BrandBanner extends StatelessWidget {
  const _BrandBanner();

  Future<void> _open(BuildContext context, SocialLink s) async {
    if (!s.hasLink) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text('El enlace de ${s.label} estará disponible pronto.')));
      return;
    }
    await launchUrl(Uri.parse(s.url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _glow.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(color: _glow.withValues(alpha: 0.25), blurRadius: 18),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: LayoutBuilder(builder: (context, box) {
          // Todas las medidas son fracciones del ancho del banner, tomadas de
          // la imagen de referencia, para que el espaciado se mantenga igual
          // en cualquier pantalla.
          final w = box.maxWidth;
          final leftW = w * 0.38; // ancho del bloque logo + lema

          // Tipografía de la referencia: Outfit (geométrica, trazo medio).
          final baseText = GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            height: 1.22,
            color: Colors.white,
          );

          return Stack(
            fit: StackFit.passthrough,
            children: [
              // Fondo en alta resolución. Si el archivo no existe, usa el
              // fondo dibujado por código como respaldo.
              Positioned.fill(
                child: Image.asset(
                  'assets/images/banner_fondo.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      CustomPaint(painter: _SwooshPainter()),
                ),
              ),
              Padding(
              padding: EdgeInsets.fromLTRB(w * 0.06, 18, w * 0.04, 18),
              child: Row(children: [
                // ---- Logo + lema
                SizedBox(
                  width: leftW,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tipografía de la referencia (condensada extra negrita).
                      AloWordmark(width: leftW * 0.87),
                      const SizedBox(height: 10),
                      // fitWidth: el lema ocupa exactamente el ancho del bloque.
                      FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text('Conecta • Disfruta • Comparte',
                            style: baseText.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                                height: 1.2)),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: w * 0.05),
                // ---- Divisor
                Container(
                  width: 2,
                  height: w * 0.25,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                SizedBox(width: w * 0.07),
                // ---- Texto + redes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Los saltos de línea son los de la referencia; fitWidth
                      // ajusta el tamaño para que la línea más larga llene el
                      // ancho disponible.
                      FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: 'Síguenos en nuestras\nredes y no te pierdas\n',
                            style: baseText,
                            children: [
                              TextSpan(
                                text: 'ningún contenido',
                                style: baseText.copyWith(
                                    color: _cyan, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: w * 0.035),
                      LayoutBuilder(builder: (context, c) {
                        const gap = 4.0;
                        final n = SocialLinks.all.length;
                        final size = ((c.maxWidth - gap * (n - 1)) / n)
                            .clamp(18.0, 30.0)
                            .toDouble();
                        return Row(children: [
                          for (var i = 0; i < n; i++) ...[
                            if (i > 0) const SizedBox(width: gap),
                            _SocialButton(
                              link: SocialLinks.all[i],
                              size: size,
                              onTap: () => _open(context, SocialLinks.all[i]),
                            ),
                          ],
                        ]);
                      }),
                    ],
                  ),
                ),
              ]),
            ),
            ],
          );
        }),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final SocialLink link;
  final double size;
  final VoidCallback onTap;
  const _SocialButton(
      {required this.link, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: link.label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Image.asset(
          link.asset,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.link_rounded,
                size: size * 0.55, color: AloColors.bgDeep),
          ),
        ),
      ),
    );
  }
}

/// Fondo del banner: degradado azul con las dos curvas cian del diseño.
class _SwooshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF0B3380), Color(0xFF062353)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    Paint stroke(double width, double alpha) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width
      ..color = _glow.withValues(alpha: alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    // Curva superior izquierda.
    final top = Path()
      ..moveTo(-8, h * 0.78)
      ..quadraticBezierTo(w * 0.03, h * 0.12, w * 0.36, -6);
    canvas.drawPath(top, stroke(14, 0.85));
    canvas.drawPath(top.shift(const Offset(10, 8)), stroke(3, 0.5));

    // Curva inferior derecha.
    final bottom = Path()
      ..moveTo(w + 8, h * 0.22)
      ..quadraticBezierTo(w * 0.97, h * 0.88, w * 0.60, h + 6);
    canvas.drawPath(bottom, stroke(14, 0.85));
    canvas.drawPath(bottom.shift(const Offset(-10, -8)), stroke(3, 0.5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ------------------------------------------------------ Contenido destacado

/// Proporción (ancho / alto) de la tarjeta de contenido destacado.
/// Más alto = más alargada hacia los lados. Para hacerla un poco más alta
/// baja este número (p. ej. 2.6); para hacerla más baja, súbelo (p. ej. 3.2).
const _featuredAspect = 2.9;

class _FeaturedRow extends StatelessWidget {
  final List<ContentItem> items;
  final VoidCallback onPlayPromo;
  const _FeaturedRow({required this.items, required this.onPlayPromo});

  @override
  Widget build(BuildContext context) {
    // Ancho completo, igual que el banner de redes de arriba.
    final cardWidth = MediaQuery.of(context).size.width - 32;
    final cardHeight = cardWidth / _featuredAspect;
    return SizedBox(
      height: cardHeight + 8, // +8 para que no se corte el brillo
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _PromoCard(onPlay: onPlayPromo),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => SizedBox(
                width: cardWidth,
                child: _FeaturedCard(item: items[i]),
              ),
            ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final ContentItem item;
  const _FeaturedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasCover = item.coverUrl != null && item.coverUrl!.isNotEmpty;
    return GestureDetector(
      onTap: () => showContentDetail(context, item),
      child: Container(
        decoration: _featuredDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: hasCover
              ? Stack(fit: StackFit.expand, children: [
                  CoverImage(item: item, showIcon: false),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AloColors.bgDeep.withValues(alpha: 0.9),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      const _PlayButton(size: 62),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(item.type.label,
                                style: const TextStyle(
                                    color: _cyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ])
              // Sin portada: la imagen de marca del diseño (destellos,
              // tipografía y cámara incluidos).
              : _PromoImage(onPlay: () => showContentDetail(context, item)),
        ),
      ),
    );
  }
}

/// Borde y brillo azul de la tarjeta destacada.
final _featuredDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: _glow.withValues(alpha: 0.6)),
  boxShadow: [
    BoxShadow(color: _glow.withValues(alpha: 0.28), blurRadius: 16),
  ],
);

/// Imagen de marca "ALO BIEN – MUCHO MÁS QUE NOTICIAS" tomada del diseño.
///
/// La imagen ya NO trae el botón de play dibujado: el play es un widget real
/// (tocable) que se coloca encima, en el mismo sitio donde estaba el dibujado.
class _PromoImage extends StatelessWidget {
  final VoidCallback onPlay;
  const _PromoImage({required this.onPlay});

  // Medidas de assets/images/banner_destacado_sin_play.png (1920 x 601 px).
  static const _imgW = 1920.0;
  static const _imgH = 601.0;
  static const _playCx = 0.1172; // centro X del play (fracción del ancho)
  static const _playCy = 0.535; // centro Y del play (fracción del alto)
  static const _playDiameter = 0.112; // diámetro (fracción del ancho)

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      // Mismo cálculo que BoxFit.cover, para que el play caiga siempre en su
      // sitio aunque la tarjeta recorte los bordes de la imagen.
      final scale = math.max(c.maxWidth / _imgW, c.maxHeight / _imgH);
      final drawnW = _imgW * scale;
      final drawnH = _imgH * scale;
      final left = (c.maxWidth - drawnW) / 2;
      final top = (c.maxHeight - drawnH) / 2;
      final cx = left + _playCx * drawnW;
      final cy = top + _playCy * drawnH;
      final d = _playDiameter * drawnW;
      final tap = math.max(d, 48.0); // área táctil mínima recomendada

      return Stack(fit: StackFit.expand, children: [
        Image.asset(
          'assets/images/banner_destacado_sin_play.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: Color(0xFF05265F)),
        ),
        Positioned(
          left: cx - tap / 2,
          top: cy - tap / 2,
          width: tap,
          height: tap,
          child: Semantics(
            button: true,
            label: 'Reproducir contenido',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPlay,
              child: Center(child: _PlayButton(size: d)),
            ),
          ),
        ),
      ]);
    });
  }
}

/// Botón de play del diseño: círculo azul oscuro con borde blanco, brillo
/// azul alrededor y un segundo anillo tenue por fuera. [size] es el diámetro
/// total (anillo exterior incluido).
class _PlayButton extends StatelessWidget {
  final double size;
  const _PlayButton({required this.size});

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.8;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.28), width: 1.5),
      ),
      child: Container(
        width: inner,
        height: inner,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xCC05265F),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: _glow.withValues(alpha: 0.6),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(Icons.play_arrow_rounded,
            size: inner * 0.64, color: Colors.white),
      ),
    );
  }
}

/// Banner de marca que se muestra mientras no haya contenido destacado.
class _PromoCard extends StatelessWidget {
  final VoidCallback onPlay;
  const _PromoCard({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _featuredDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: _PromoImage(onPlay: onPlay),
      ),
    );
  }
}

// ------------------------------------------------------------- Productos

class _Products extends StatelessWidget {
  const _Products();

  @override
  Widget build(BuildContext context) {
    void tienda() => _openWeb(context, 'Tienda', AppConfig.tabs[3].uri);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: _ProductCard(
            asset: 'assets/images/producto_viceras.png',
            line1: 'Viceras',
            line2: 'ORIGINALES',
            onTap: tienda,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProductCard(
            asset: 'assets/images/producto_llaveros.png',
            line1: 'LLAVEROS',
            line2: 'originales',
            onTap: tienda,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProductCard(
            asset: 'assets/images/producto_verificacion.png',
            line1: 'Verificación',
            line2: 'de integrante',
            // El formulario de verificación está en la página principal del sitio.
            onTap: () => _openWeb(context, 'Verificación de integrante',
                Uri.https(AppConfig.host, '/')),
          ),
        ),
      ]),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String asset;
  final String line1;
  final String line2;
  final VoidCallback onTap;
  const _ProductCard({
    required this.asset,
    required this.line1,
    required this.line2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B4D95), Color(0xFF0A2142)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 199 / 154,
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AloColors.indicator,
                  child: const Icon(Icons.shopping_bag_rounded,
                      size: 36, color: Colors.white54),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 12),
            child: Column(children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(line1,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(line2,
                    style: const TextStyle(fontSize: 11, color: _lightText)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ----------------------------------------------------- Filas de contenido

class _ContentRow extends StatelessWidget {
  final List<ContentItem> items;
  const _ContentRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 256,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => ContentCard(
          item: items[i],
          onTap: () => showContentDetail(context, items[i]),
        ),
      ),
    );
  }
}