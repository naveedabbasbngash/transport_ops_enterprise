import '../entities/client_entity.dart';

abstract class ClientRepository {
  Future<List<ClientEntity>> getClients({String? status, String? search});

  Future<ClientEntity> createClient({
    required String name,
    String? status,
    String? externalRef,
  });

  Future<ClientEntity> updateClient({
    required String id,
    String? name,
    String? status,
    String? externalRef,
  });

  Future<void> deleteClient(String id);
}
