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
}
