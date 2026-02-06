import '../entities/trip_entity.dart';

abstract class TripsRepository {
  Future<List<TripEntity>> getTrips({
    String query = '',
  });
}
