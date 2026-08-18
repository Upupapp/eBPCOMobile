import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/cards/app_card.dart';

/// Small summary counter card, e.g. "In Progress: 1", used in a responsive
/// grid.
///
/// [onTap] is how the counter earns its place: a number the applicant cannot
/// act on is decoration, so every counter navigates to the set it counted.
class DashboardStatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DashboardStatCard({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text('$count', style: AppTypography.statistic.copyWith(fontSize: 22)),
          Text(
            label,
            style: AppTypography.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
