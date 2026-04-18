import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool showChevron;

  const SettingsRow({
    Key? key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.showChevron = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
              const SizedBox(width: 8),
            ],
            if (showChevron)
              const Icon(Icons.chevron_right, color: AppTheme.borderColor),
          ],
        ),
      ),
    );
  }
}