import '../../../core/network/api_client.dart';
import '../../../core/network/api_list_parser.dart';
import '../../auth/data/auth_local_source.dart';
import '../domain/entities/provider_entity.dart';
import '../domain/repositories/provider_repository.dart';
import 'provider_mapper.dart';

class ProviderRepositoryImpl implements ProviderRepository {
  final ApiClient _apiClient;

  const ProviderRepositoryImpl(this._apiClient);

  @override
  Future<List<ProviderEntity>> getProviders({
    String? status,
    String? search,
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final response = await _apiClient.getJson(
      'vendors',
      query: {
        if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final items = extractListFromResponse(response);
    return items.map(providerFromApi).toList();
  }

  @override
  Future<ProviderEntity> createProvider({
    required String name,
    required String type,
    String? status,
    String? phone,
    String? externalRef,
    String? notes,
  }) async {
    final companyId = await AuthLocalSource.getCompanyId();
    final response = await _apiClient.postJson(
      'vendors',
      body: {
        if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
        'name': name,
        'type': type,
        if (status != null && status.isNotEmpty) 'status': status,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (externalRef != null && externalRef.isNotEmpty)
          'external_ref': externalRef,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) return providerFromApi(data);
    if (data is Map) return providerFromApi(data.cast<String, dynamic>());

    final items = extractListFromResponse(response);
    if (items.isNotEmpty) return providerFromApi(items.first);

    return ProviderEntity(
      id: '',
      name: name,
      status: status ?? 'active',
      type: type,
      phone: phone,
      externalRef: externalRef,
      notes: notes,
    );
  }
}
