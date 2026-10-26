import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/content_item.dart';

class CoverImage extends StatelessWidget {
  final ContentItem item;
  final BoxFit fit;
  const CoverImage({super.key, required this.item, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AloColors.violet, AloColors.bgDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(item.type.icon, size: 44, color: Colors.white70),
      ),
    );
    final url = item.coverUrl;
    if (url == null) return placeholder;
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}