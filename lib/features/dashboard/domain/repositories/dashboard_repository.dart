import '../entities/dashboard_summary.dart';
import '../entities/dashboard_period.dart';

abstract class DashboardRepository {
  Future<DashboardSummary> getSummary({required DashboardPeriod period});
}
