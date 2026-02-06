import '../../../trips/domain/entities/trip_entity.dart';
import '../repositories/reports_repository.dart';

class GetAllReportTrips {
  final ReportsRepository _reportsRepository;

  const GetAllReportTrips(this._reportsRepository);

  Future<List<TripEntity>> call() {
    return _reportsRepository.getAllTrips();
  }
}
