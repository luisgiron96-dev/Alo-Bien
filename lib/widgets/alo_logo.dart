import 'package:flutter/material.dart';

/// Logo de ALO BIEN sin el fondo morado.
///
/// Usa tu mismo assets/images/logo.png, pero convierte el brillo de cada píxel
/// en transparencia: el texto blanco queda opaco y el fondo oscuro desaparece.
class AloLogo extends StatelessWidget {
  final double height;
  final Alignment alignment;
  const AloLogo({
    super.key,
    required this.height,
    this.alignment = Alignment.center,
  });

  static const _filter = ColorFilter.matrix(<double>[
    0, 0, 0, 0, 255, //
    0, 0, 0, 0, 255,
    0, 0, 0, 0, 255,
    1.5, 2.9, 0.6, 0, -230,
  ]);

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: _filter,
      child: Image.asset(
        'assets/images/logo.png',
        height: height,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Text(
          'ALO BIEN',
          style: TextStyle(
            fontSize: height * 0.7,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
