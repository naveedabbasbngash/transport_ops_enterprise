import '../entities/report_models.dart';
import '../../../trips/domain/entities/trip_entity.dart';

abstract class ReportsRepository {
  Future<DailyReport> getDailyReport(DateTime date);

  Future<MonthlyComparisonReport> getMonthlyComparisonReport(DateTime month);

  Future<ReportDataQuality> getLatestDataQuality();

  Future<List<TripEntity>> getAllTrips();
}
