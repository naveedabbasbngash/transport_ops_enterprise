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
    List<int>? registrationCardBytes,
    String? registrationCardFileName,
    String? ownership,
    String? vendorId,
    String? ownerName,
    String? companyName,
    String? notes,
  });
}
