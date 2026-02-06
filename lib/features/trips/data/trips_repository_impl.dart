import '../domain/entities/trip_entity.dart';
import '../domain/repositories/trips_repository.dart';
import 'trip_local_store.dart';

class TripsRepositoryImpl implements TripsRepository {
  final TripLocalStore _tripLocalStore;

  const TripsRepositoryImpl({
    required TripLocalStore tripLocalStore,
  }) : _tripLocalStore = tripLocalStore;

  @override
  Future<List<TripEntity>> getTrips({
    String query = '',
  }) {
    return _tripLocalStore.getTrips(query: query);
  }
}
