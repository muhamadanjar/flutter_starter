import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/dashboard.dart';

class RecentActivityWidget extends StatelessWidget {
  final List<RecentActivity> activities;

  const RecentActivityWidget({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: AppTypography.labelLarge.copyWith(color: context.colors.textPrimary),
              ),
              TextButton(
                onPressed: () {/* TODO: View all activities */},
                child: Text(
                  'View All',
                  style: AppTypography.labelMedium.copyWith(color: context.colors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No recent activity',
                  style: AppTypography.bodyMedium.copyWith(color: context.colors.textHint),
                ),
              ),
            )
          else
            ...activities.map((activity) => _ActivityItem(activity: activity)),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final RecentActivity activity;

  const _ActivityItem({required this.activity});

  Color _getTypeColor(BuildContext context) {
    switch (activity.type) {
      case 'order':
        return context.colors.secondary;
      case 'payment':
        return context.colors.success;
      case 'user':
        return context.colors.info;
      case 'alert':
        return context.colors.warning;
      default:
        return context.colors.primary;
    }
  }

  IconData _getTypeIcon() {
    switch (activity.type) {
      case 'order':
        return Icons.shopping_bag_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'user':
        return Icons.person_rounded;
      case 'alert':
        return Icons.warning_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getTypeColor(context).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getTypeIcon(), color: _getTypeColor(context), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: AppTypography.labelMedium.copyWith(color: context.colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: AppTypography.bodySmall.copyWith(color: context.colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormatter.formatRelative(activity.timestamp),
            style: AppTypography.caption.copyWith(color: context.colors.textHint),
          ),
        ],
      ),
    );
  }
}
