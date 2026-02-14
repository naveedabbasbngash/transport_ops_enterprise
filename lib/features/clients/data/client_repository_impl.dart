import '../../../core/network/api_client.dart';
import '../../../core/network/api_list_parser.dart';
import '../../auth/data/auth_local_source.dart';
import '../domain/entities/client_entity.dart';
import '../domain/repositories/client_repository.dart';
import 'client_mapper.dart';

class ClientRepositoryImpl implements ClientRepository {
  final ApiClient _apiClient;

  const ClientRepositoryImpl(this._apiClient);

  @override
  Future<List<ClientEntity>> getClients({
    String? status,
    String? search,
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final response = await _apiClient.getJson(
      'clients',
      query: {
        if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final items = extractListFromResponse(response);
    return items.map(clientFromApi).toList();
  }

  @override
  Future<ClientEntity> createClient({
    required String name,
    String? status,
    String? externalRef,
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final response = await _apiClient.postJson(
      'clients',
      body: {
        if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
        'name': name,
        if (status != null && status.isNotEmpty) 'status': status,
        if (externalRef != null && externalRef.isNotEmpty)
          'external_ref': externalRef,
      },
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) return clientFromApi(data);
    if (data is Map) return clientFromApi(data.cast<String, dynamic>());

    final items = extractListFromResponse(response);
    if (items.isNotEmpty) return clientFromApi(items.first);

    return ClientEntity(
      id: '',
      name: name,
      status: status ?? 'active',
      externalRef: externalRef,
    );
  }
}
