import '../entities/trip_entity.dart';
import '../repositories/trips_repository.dart';

class GetTrips {
  final TripsRepository _tripsRepository;

  const GetTrips(this._tripsRepository);

  Future<List<TripEntity>> call({
    String query = '',
  }) {
    return _tripsRepository.getTrips(query: query);
  }
}
