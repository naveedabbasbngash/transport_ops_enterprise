import '../entities/report_models.dart';
import '../repositories/reports_repository.dart';

class GetMonthlyComparisonReport {
  final ReportsRepository _reportsRepository;

  const GetMonthlyComparisonReport(this._reportsRepository);

  Future<MonthlyComparisonReport> call(DateTime month) {
    return _reportsRepository.getMonthlyComparisonReport(month);
  }
}
