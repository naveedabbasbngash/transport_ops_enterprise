import '../entities/provider_entity.dart';

abstract class ProviderRepository {
  Future<List<ProviderEntity>> getProviders({String? status, String? search});

  Future<ProviderEntity> createProvider({
    required String name,
    required String type,
    String? status,
    String? phone,
    String? externalRef,
    String? notes,
  });
}
