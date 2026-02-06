import '../entities/report_models.dart';
import '../repositories/reports_repository.dart';

class GetLatestDataQuality {
  final ReportsRepository _reportsRepository;

  const GetLatestDataQuality(this._reportsRepository);

  Future<ReportDataQuality> call() {
    return _reportsRepository.getLatestDataQuality();
  }
}
