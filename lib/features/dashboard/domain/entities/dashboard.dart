import 'package:equatable/equatable.dart';

class DashboardData extends Equatable {
  final int totalUsers;
  final int activeUsers;
  final double totalRevenue;
  final double revenueGrowth;
  final int totalOrders;
  final double orderGrowth;
  final List<ChartDataPoint> revenueChart;
  final List<RecentActivity> recentActivities;
  final List<StatCard> statCards;

  const DashboardData({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.totalRevenue = 0,
    this.revenueGrowth = 0,
    this.totalOrders = 0,
    this.orderGrowth = 0,
    this.revenueChart = const [],
    this.recentActivities = const [],
    this.statCards = const [],
  });

  @override
  List<Object?> get props => [totalUsers, activeUsers, totalRevenue, revenueGrowth, totalOrders, orderGrowth];
}

class ChartDataPoint extends Equatable {
  final String label;
  final double value;

  const ChartDataPoint({required this.label, required this.value});

  @override
  List<Object?> get props => [label, value];
}

class RecentActivity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String type;
  final DateTime timestamp;

  const RecentActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, title, type, timestamp];
}

class StatCard extends Equatable {
  final String title;
  final String value;
  final String? subtitle;
  final double? change;
  final String icon;

  const StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.change,
    this.icon = 'default',
  });

  @override
  List<Object?> get props => [title, value, subtitle, change, icon];
}
