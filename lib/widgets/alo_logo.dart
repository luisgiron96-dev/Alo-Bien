import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Logo de ALO BIEN (blanco, con fondo transparente).
///
/// Usa assets/images/logo.png, que ya es un PNG transparente: se ve limpio
/// sobre cualquier color de fondo.
class AloLogo extends StatelessWidget {
  final double height;
  final Alignment alignment;
  const AloLogo({
    super.key,
    required this.height,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
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