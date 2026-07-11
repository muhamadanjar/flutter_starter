import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class StatCardWidget extends StatelessWidget {

  const StatCardWidget({
    super.key,
    required this.title,
    required this.value,
    this.change,
    required this.icon,
    required this.color,
  });
  final String title;
  final String value;
  final double? change;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (change! >= 0 ? context.colors.success : context.colors.error).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        change! >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 12,
                        color: change! >= 0 ? context.colors.success : context.colors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${change! >= 0 ? '+' : ''}${change!.toStringAsFixed(1)}%',
                        style: AppTypography.labelSmall.copyWith(
                          color: change! >= 0 ? context.colors.success : context.colors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(color: context.colors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(color: context.colors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
