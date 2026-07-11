import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/dashboard.dart';

class RevenueChartWidget extends StatelessWidget {

  const RevenueChartWidget({super.key, required this.data});
  final List<ChartDataPoint> data;

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
                'Revenue Overview',
                style: AppTypography.labelLarge.copyWith(color: context.colors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'This Month',
                  style: AppTypography.labelSmall.copyWith(color: context.colors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: AppTypography.bodyMedium.copyWith(color: context.colors.textHint),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: context.colors.divider.withValues(alpha: 0.3),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) => Text(
                              '\$${(value / 1000).toStringAsFixed(0)}k',
                              style: AppTypography.caption.copyWith(color: context.colors.textHint),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 && value.toInt() < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    data[value.toInt()].label,
                                    style: AppTypography.caption.copyWith(color: context.colors.textHint),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
                          isCurved: true,
                          gradient: AppColors.primaryGradient,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [context.colors.primary.withValues(alpha: 0.3), context.colors.primary.withValues(alpha: 0.0)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => context.colors.surface,
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '\$${spot.y.toStringAsFixed(0)}',
                              AppTypography.labelMedium.copyWith(color: context.colors.textPrimary),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
