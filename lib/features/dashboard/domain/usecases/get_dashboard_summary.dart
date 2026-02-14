import '../entities/dashboard_summary.dart';
import '../entities/dashboard_period.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardSummary {
  final DashboardRepository _repository;

  const GetDashboardSummary(this._repository);

  Future<DashboardSummary> call({required DashboardPeriod period}) {
    return _repository.getSummary(period: period);
  }
}
