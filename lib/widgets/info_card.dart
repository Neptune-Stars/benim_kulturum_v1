import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? metadata;
  final Widget? badge;
  final bool showChevron;
  final VoidCallback? onTap;
  final Widget? leading;

  const InfoCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.metadata,
    this.badge,
    this.showChevron = true,
    this.onTap,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    final subtitleColor = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;
    final metadataColor = isDark ? Colors.white : AppTheme.textPrimary;
    final chevronColor = isDark ? Colors.white70 : AppTheme.textMuted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: titleColor,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Flexible(child: Align(alignment: Alignment.topRight, child: badge!)),
                        ],
                      ],
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 14,
                          height: 1.25,
                        ),
                      ),
                    ],
                    if (metadata != null && metadata!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        metadata!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: metadataColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: chevronColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
