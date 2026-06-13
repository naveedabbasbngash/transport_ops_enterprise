import '../entities/driver_entity.dart';

abstract class DriverRepository {
  Future<List<DriverEntity>> getDrivers({
    String? status,
    String? search,
  });

  Future<DriverEntity> createDriver({
    required String name,
    required String phone,
    required String residentId,
    required List<int> iqamaBytes,
    required String iqamaFileName,
  });

  Future<DriverEntity> updateDriver({
    required String id,
    String? name,
    String? phone,
    String? residentId,
    String? driverType,
    String? status,
    String? vendorId,
    List<int>? iqamaBytes,
    String? iqamaFileName,
  });

  Future<void> deleteDriver(String id);
}
