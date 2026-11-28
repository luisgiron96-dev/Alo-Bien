import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Pantalla de bienvenida animada de ALO BIEN.
///
/// Arranca igual que el splash nativo (logo centrado sobre el azul marino),
/// de modo que el cambio no se nota, y luego cuenta lo que hace la marca:
///  - ondas de señal que salen del logo (emisión / sonido),
///  - un destello de luz que cruza el logo (fotografía),
///  - cinco íconos que aparecen uno a uno: Fotografía, Video, Sonido
///    (ecualizador animado), Documental y Multimedia,
///  - la frase "Conecta • Disfruta • Comparte".
///
/// La app real (AuthGate) ya se está cargando debajo, así que no retrasa
/// nada. Se puede saltar tocando la pantalla.
class AnimatedSplash extends StatefulWidget {
  final Widget child;
  const AnimatedSplash({super.key, required this.child});

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with SingleTickerProviderStateMixin {
  static const _totalMs = 3800;
  static const _seconds = _totalMs / 1000;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _totalMs),
  );
  bool _done = false;
  bool _checkedMotion = false;

  static const _items = <_Item>[
    _Item('Fotografía', Icons.photo_camera_rounded),
    _Item('Video', Icons.videocam_rounded),
    _Item('Sonido', null), // ecualizador animado
    _Item('Documental', Icons.theaters_rounded),
    _Item('Multimedia', Icons.perm_media_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _done = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedMotion) return;
    _checkedMotion = true;
    // Si el usuario desactivó las animaciones del sistema, se omite.
    if (MediaQuery.of(context).disableAnimations) {
      _done = true;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _skip() {
    if (_c.isAnimating) {
      _c.animateTo(1.0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (!_done)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _skip,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => _frame(context, _c.value),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- helpers

  static double _iv(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0).toDouble();

  Widget _frame(BuildContext context, double t) {
    final size = MediaQuery.sizeOf(context);

    // Tamaños (el logo parte con un tamaño parecido al del splash nativo).
    final logoW = math.min(size.width * 0.38, 190.0);
    final logoH = logoW * 222 / 720;
    final itemW = (size.width - 40) / 5;
    final chip = math.min(56.0, itemW - 8);
    const gapLogo = 30.0;
    const labelH = 12.0;
    final chipsH = chip + 6 + labelH;
    const gapTag = 18.0;
    const tagH = 16.0;
    final colH = logoH + gapLogo + chipsH + gapTag + tagH;
    final k = (colH - logoH) / 2;

    // El logo sube para dejar espacio a los íconos.
    final slide = Curves.easeInOutCubic.transform(_iv(t, 0.10, 0.32));
    final dy = k * (1 - slide);
    final logoCenter = Offset(size.width / 2, size.height / 2 + dy - k);

    // Destello de luz que cruza el logo.
    final sweep = Curves.easeInOut.transform(_iv(t, 0.30, 0.55));

    // Ola de brillo que recorre los íconos al final.
    final wave = _iv(t, 0.66, 0.90);
    // Fuera de la ventana de la ola no hay brillo en ningún ícono.
    final pos = (wave <= 0 || wave >= 1) ? -10.0 : wave * 6.5 - 0.75;

    final out = 1 - Curves.easeIn.transform(_iv(t, 0.93, 1.0));

    return Opacity(
      opacity: out,
      child: Material(
        color: AloColors.bg,
        child: Stack(
          children: [
            // Ondas de señal detrás del logo.
            Positioned.fill(
              child: CustomPaint(
                painter: _RingsPainter(
                  center: logoCenter,
                  phase: (t * _seconds / 1.9),
                  minR: logoW * 0.46,
                  maxR: size.shortestSide * 0.95,
                ),
              ),
            ),
            Center(
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: logoH,
                      child: ShaderMask(
                        blendMode: BlendMode.srcATop,
                        shaderCallback: (r) {
                          final p = -0.4 + 1.8 * sweep;
                          return LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: const [
                              Colors.white,
                              Color(0xFF8FB8FF),
                              Colors.white,
                            ],
                            stops: [
                              (p - 0.18).clamp(0.0, 1.0).toDouble(),
                              p.clamp(0.0, 1.0).toDouble(),
                              (p + 0.18).clamp(0.0, 1.0).toDouble(),
                            ],
                          ).createShader(r);
                        },
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: logoW,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    const SizedBox(height: gapLogo),
                    SizedBox(
                      height: chipsH,
                      width: itemW * 5,
                      child: Row(
                        children: [
                          for (var i = 0; i < _items.length; i++)
                            SizedBox(
                              width: itemW,
                              child: _chip(i, t, chip, labelH, pos),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: gapTag),
                    SizedBox(
                      height: tagH,
                      child: Opacity(
                        opacity: _iv(t, 0.55, 0.72),
                        child: const Text(
                          'CONECTA  •  DISFRUTA  •  COMPARTE',
                          style: TextStyle(
                            color: AloColors.lavender,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(int i, double t, double size, double labelH, double pos) {
    final item = _items[i];
    final start = 0.24 + 0.07 * i;
    final raw = _iv(t, start, start + 0.18);
    final scale = Curves.easeOutBack.transform(raw);
    final opacity = Curves.easeOut.transform(raw);
    final glow = (1 - (pos - i).abs()).clamp(0.0, 1.0).toDouble();

    Widget inner;
    if (item.icon != null) {
      inner = Icon(item.icon, color: Colors.white, size: size * 0.46);
    } else {
      inner = CustomPaint(
        size: Size(size * 0.5, size * 0.4),
        painter: _BarsPainter(seconds: t * _seconds, appear: raw),
      );
    }

    // Flash de cámara al aparecer el primer ícono.
    final flash = i == 0 ? _iv(t, start + 0.14, start + 0.27) : 0.0;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - raw)),
        child: Column(
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AloColors.indicator.withValues(alpha: 0.55 + 0.25 * glow),
                  border: Border.all(
                    color: AloColors.lavender.withValues(alpha: 0.25 + 0.6 * glow),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AloColors.lavender.withValues(alpha: 0.35 * glow),
                      blurRadius: 18 * glow,
                      spreadRadius: 1 * glow,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    inner,
                    if (flash > 0 && flash < 1)
                      Container(
                        width: size * (0.4 + 0.6 * flash),
                        height: size * (0.4 + 0.6 * flash),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.85 * (1 - flash)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: labelH,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label.toUpperCase(),
                  style: TextStyle(
                    color: AloColors.lavender.withValues(alpha: 0.85 + 0.15 * glow),
                    fontSize: 9,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item {
  final String label;
  final IconData? icon;
  const _Item(this.label, this.icon);
}

/// Ondas de señal que salen del logo.
class _RingsPainter extends CustomPainter {
  final Offset center;
  final double phase;
  final double minR;
  final double maxR;
  const _RingsPainter({
    required this.center,
    required this.phase,
    required this.minR,
    required this.maxR,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final p = (phase + i / 3) % 1.0;
      final r = minR + (maxR - minR) * Curves.easeOut.transform(p);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AloColors.lavender.withValues(alpha: 0.20 * (1 - p));
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.phase != phase || old.center != center;
}

/// Ecualizador de sonido.
class _BarsPainter extends CustomPainter {
  final double seconds;
  final double appear;
  const _BarsPainter({required this.seconds, required this.appear});

  @override
  void paint(Canvas canvas, Size size) {
    const n = 4;
    final barW = size.width / (n * 2 - 1);
    final paint = Paint()..color = Colors.white;
    for (var j = 0; j < n; j++) {
      final h = size.height *
          (0.3 + 0.7 * math.sin(seconds * 6 + j * 1.4).abs()) *
          appear;
      final x = j * barW * 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - h) / 2, barW, h),
        Radius.circular(barW / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.seconds != seconds || old.appear != appear;
}