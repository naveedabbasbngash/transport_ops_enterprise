class DashboardRecentTrip {
  final String id;
  final String route;
  final String date;
  final String status;
  final double revenue;

  const DashboardRecentTrip({
    required this.id,
    required this.route,
    required this.date,
    required this.status,
    required this.revenue,
  });
}

class DashboardSummary {
  final int totalTrips;
  final int totalClients;
  final int totalProviders;
  final int totalDrivers;
  final int activeDrivers;
  final int totalTrucks;
  final int activeTrucks;
  final int totalExpenses;
  final double recentRevenue;
  final List<DashboardRecentTrip> recentTrips;
  final DateTime refreshedAt;

  const DashboardSummary({
    required this.totalTrips,
    required this.totalClients,
    required this.totalProviders,
    required this.totalDrivers,
    required this.activeDrivers,
    required this.totalTrucks,
    required this.activeTrucks,
    required this.totalExpenses,
    required this.recentRevenue,
    required this.recentTrips,
    required this.refreshedAt,
  });

  factory DashboardSummary.empty() {
    return DashboardSummary(
      totalTrips: 0,
      totalClients: 0,
      totalProviders: 0,
      totalDrivers: 0,
      activeDrivers: 0,
      totalTrucks: 0,
      activeTrucks: 0,
      totalExpenses: 0,
      recentRevenue: 0,
      recentTrips: const <DashboardRecentTrip>[],
      refreshedAt: DateTime.now(),
    );
  }
}
