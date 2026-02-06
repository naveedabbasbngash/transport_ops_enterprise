import '../entities/report_models.dart';
import '../repositories/reports_repository.dart';

class GetDailyReport {
  final ReportsRepository _reportsRepository;

  const GetDailyReport(this._reportsRepository);

  Future<DailyReport> call(DateTime date) {
    return _reportsRepository.getDailyReport(date);
  }
}
