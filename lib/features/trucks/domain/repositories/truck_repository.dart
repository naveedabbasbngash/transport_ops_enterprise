import '../entities/truck_entity.dart';

abstract class TruckRepository {
  Future<List<TruckEntity>> getTrucks({
    String? status,
    String? search,
  });

  Future<TruckEntity> createTruck({
    required String plateNo,
    String? truckType,
    String? color,
    String? model,
    String? makeYear,
    String? registrationNumber,
    String? ownership,
    String? vendorId,
    String? notes,
  });
}
