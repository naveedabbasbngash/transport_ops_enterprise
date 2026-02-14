enum DashboardPeriod { today, last7Days, last30Days }

extension DashboardPeriodX on DashboardPeriod {
  String get label {
    switch (this) {
      case DashboardPeriod.today:
        return 'Today';
      case DashboardPeriod.last7Days:
        return '7D';
      case DashboardPeriod.last30Days:
        return '30D';
    }
  }
}
