class ReportTotals {
  final int tripCount;
  final double revenue;
  final double vendorCost;
  final double otherCost;
  final double profit;

  const ReportTotals({
    required this.tripCount,
    required this.revenue,
    required this.vendorCost,
    required this.otherCost,
    required this.profit,
  });

  static const zero = ReportTotals(
    tripCount: 0,
    revenue: 0,
    vendorCost: 0,
    otherCost: 0,
    profit: 0,
  );
}

class TopMetric {
  final String label;
  final int count;

  const TopMetric({
    required this.label,
    required this.count,
  });
}

class DailyReport {
  final DateTime date;
  final ReportTotals totals;
  final List<TopMetric> topClients;
  final List<TopMetric> topRoutes;

  const DailyReport({
    required this.date,
    required this.totals,
    required this.topClients,
    required this.topRoutes,
  });
}

class MonthlyComparisonReport {
  final DateTime month;
  final ReportTotals currentMonthTotals;
  final ReportTotals previousMonthTotals;

  const MonthlyComparisonReport({
    required this.month,
    required this.currentMonthTotals,
    required this.previousMonthTotals,
  });
}

class ReportDataQuality {
  final int updatedNotApplied;
  final int needsReview;
  final int errorRows;

  const ReportDataQuality({
    required this.updatedNotApplied,
    required this.needsReview,
    required this.errorRows,
  });

  static const zero = ReportDataQuality(
    updatedNotApplied: 0,
    needsReview: 0,
    errorRows: 0,
  );
}
