import '../entities/client_entity.dart';
import '../entities/create_trip_input.dart';
import '../entities/trip_entity.dart';
import '../entities/vendor_entity.dart';

abstract class TripsRepository {
  Future<List<TripEntity>> getTrips({
    String query = '',
    String? status,
    bool missingWaybillOnly = false,
  });

  Future<TripEntity?> getTripById(String id);

  Future<List<ClientEntity>> getClients({
    String status = 'active',
    String search = '',
  });

  Future<List<VendorEntity>> getVendors({
    String status = 'active',
    String search = '',
  });

  Future<TripEntity> createTrip(CreateTripInput input);

  Future<TripEntity> updateTrip(String id, CreateTripInput input);

  Future<TripEntity> updateTripStatus(String id, String status);

  Future<void> deleteTrip(String id);

  Future<TripWaybillFile> uploadTripWaybill({
    required String tripId,
    required List<int> bytes,
    required String fileName,
  });

  Future<void> deleteTripWaybill({
    required String tripId,
    required String fileId,
  });
}
