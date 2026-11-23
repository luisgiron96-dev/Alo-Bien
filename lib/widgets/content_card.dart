import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/content_item.dart';
import 'cover_image.dart';

class NewBadge extends StatelessWidget {
  const NewBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AloColors.violet,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('NUEVO',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
      );
}

class ContentCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onTap;
  const ContentCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 2 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CoverImage(item: item),
                  ),
                ),
                if (item.isNew)
                  const Positioned(top: 8, left: 8, child: NewBadge()),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                        color: Colors.black54, shape: BoxShape.circle),
                    child: Icon(item.type.icon, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            if (item.price != null && item.price!.isNotEmpty)
              Text(item.price!,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AloColors.lavender)),
          ],
        ),
      ),
    );
  }
}