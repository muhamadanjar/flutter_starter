import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/adaptive_layout.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart' as err;
import '../../domain/entities/dashboard.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stat_card_widget.dart';
import '../widgets/revenue_chart_widget.dart';
import '../widgets/recent_activity_widget.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: context.colors.primary,
        backgroundColor: context.colors.surface,
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: context.colors.background,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Dashboard',
                  style: AppTypography.headlineSmall.copyWith(color: context.colors.textPrimary),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: context.colors.textSecondary),
                  onPressed: () {/* TODO: Notifications */},
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Content
            if (state.isLoading && state.data == null)
              const SliverFillRemaining(
                child: LoadingWidget(message: 'Loading dashboard...'),
              )
            else if (state.errorMessage != null && state.data == null)
              SliverFillRemaining(
                child: err.AppErrorWidget(
                  message: state.errorMessage,
                  onRetry: () => ref.read(dashboardProvider.notifier).loadDashboard(),
                ),
              )
            else
              ..._buildContent(state),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(DashboardState state) {
    final data = state.data;
    if (data == null) return [];

    return [
      // Offline banner
      if (state.isOffline)
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: context.colors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing cached data. Connect to internet for latest.',
                    style: AppTypography.bodySmall.copyWith(color: context.colors.warning),
                  ),
                ),
              ],
            ),
          ),
        ),

      // Stat Cards (Adaptive Grid)
      AdaptiveSliverGrid(
        mobileColumns: 1,
        tabletColumns: 2,
        desktopColumns: 4,
        childAspectRatio: 1.4,
        children: [
          StatCardWidget(
            title: 'Total Revenue',
            value: DateFormatter.formatCurrency(data.totalRevenue),
            change: data.revenueGrowth,
            icon: Icons.account_balance_wallet_rounded,
            color: context.colors.primary,
          ),
          StatCardWidget(
            title: 'Total Orders',
            value: DateFormatter.formatNumber(data.totalOrders),
            change: data.orderGrowth,
            icon: Icons.shopping_bag_rounded,
            color: context.colors.secondary,
          ),
          StatCardWidget(
            title: 'Total Users',
            value: DateFormatter.formatNumber(data.totalUsers),
            icon: Icons.people_rounded,
            color: context.colors.info,
          ),
          StatCardWidget(
            title: 'Active Users',
            value: DateFormatter.formatNumber(data.activeUsers),
            icon: Icons.person_rounded,
            color: context.colors.success,
          ),
        ],
      ),

      // Revenue Chart
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: RevenueChartWidget(data: data.revenueChart),
        ),
      ),

      // Recent Activities
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: RecentActivityWidget(activities: data.recentActivities),
        ),
      ),
    ];
  }
}
