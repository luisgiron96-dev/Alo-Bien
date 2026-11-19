import 'package:flutter/material.dart';

import '../core/theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String moreLabel;
  final VoidCallback? onMore;
  const SectionHeader({
    super.key,
    required this.title,
    this.moreLabel = 'Ver más',
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
      child: Row(children: [
        Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        if (onMore != null)
          InkWell(
            onTap: onMore,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(children: [
                Text(moreLabel,
                    style: const TextStyle(
                        color: AloColors.lavender,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AloColors.lavender),
              ]),
            ),
          ),
      ]),
    );
  }
}