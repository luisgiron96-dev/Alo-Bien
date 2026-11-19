import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// Texto "ALO BIEN" con la tipografía del banner de referencia:
/// condensada, extra negrita y en mayúsculas (Anton), nítida a cualquier
/// tamaño porque es texto y no una imagen ampliada.
///
/// [width] es el ancho que ocupará el texto; el tamaño de la letra se ajusta
/// solo para llenarlo.
class AloWordmark extends StatelessWidget {
  final double width;
  const AloWordmark({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: Text(
          'ALO BIEN',
          maxLines: 1,
          style: GoogleFonts.anton(
            fontSize: 100,
            height: 1.05,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}