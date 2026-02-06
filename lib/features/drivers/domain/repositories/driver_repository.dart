import '../entities/driver_entity.dart';

abstract class DriverRepository {
  Future<List<DriverEntity>> getDrivers({
    String? status,
    String? search,
  });

  Future<DriverEntity> createDriver({
    required String name,
    required String driverType,
    String? phone,
    String? residentId,
    String? vendorId,
    String? licenseNo,
    String? licenseExpiry,
    String? notes,
  });
}
