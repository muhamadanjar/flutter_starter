import '../../domain/entities/dashboard.dart';

class DashboardDataModel extends DashboardData {
  const DashboardDataModel({
    super.totalUsers,
    super.activeUsers,
    super.totalRevenue,
    super.revenueGrowth,
    super.totalOrders,
    super.orderGrowth,
    super.revenueChart,
    super.recentActivities,
    super.statCards,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    return DashboardDataModel(
      totalUsers: json['total_users'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      revenueGrowth: (json['revenue_growth'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['total_orders'] as int? ?? 0,
      orderGrowth: (json['order_growth'] as num?)?.toDouble() ?? 0.0,
      revenueChart: (json['revenue_chart'] as List?)
              ?.map((e) => ChartDataPointModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentActivities: (json['recent_activities'] as List?)
              ?.map((e) => RecentActivityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      statCards: (json['stat_cards'] as List?)
              ?.map((e) => StatCardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'total_users': totalUsers,
        'active_users': activeUsers,
        'total_revenue': totalRevenue,
        'revenue_growth': revenueGrowth,
        'total_orders': totalOrders,
        'order_growth': orderGrowth,
        'revenue_chart': revenueChart.map((e) => (e as ChartDataPointModel).toJson()).toList(),
        'recent_activities': recentActivities.map((e) => (e as RecentActivityModel).toJson()).toList(),
        'stat_cards': statCards.map((e) => (e as StatCardModel).toJson()).toList(),
      };

  Map<String, dynamic> toLocalJson() => toJson();

  factory DashboardDataModel.fromLocalJson(Map<String, dynamic> json) => DashboardDataModel.fromJson(json);
}

class ChartDataPointModel extends ChartDataPoint {
  const ChartDataPointModel({required super.label, required super.value});

  factory ChartDataPointModel.fromJson(Map<String, dynamic> json) {
    return ChartDataPointModel(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}

class RecentActivityModel extends RecentActivity {
  const RecentActivityModel({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    required super.timestamp,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
      };
}

class StatCardModel extends StatCard {
  const StatCardModel({
    required super.title,
    required super.value,
    super.subtitle,
    super.change,
    super.icon,
  });

  factory StatCardModel.fromJson(Map<String, dynamic> json) {
    return StatCardModel(
      title: json['title'] as String? ?? '',
      value: json['value'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      change: (json['change'] as num?)?.toDouble(),
      icon: json['icon'] as String? ?? 'default',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'value': value,
        'subtitle': subtitle,
        'change': change,
        'icon': icon,
      };
}
