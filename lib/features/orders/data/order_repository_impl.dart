import '../../../core/network/api_client.dart';
import '../../../core/network/api_list_parser.dart';
import '../domain/entities/order_entity.dart';
import '../domain/repositories/order_repository.dart';
import 'order_mapper.dart';

class OrderRepositoryImpl implements OrderRepository {
  final ApiClient _apiClient;

  const OrderRepositoryImpl(this._apiClient);

  @override
  Future<List<OrderEntity>> getOrders({
    String query = '',
    String? status,
  }) async {
    final response = await _apiClient.getJson(
      'orders',
      query: {
        if (query.trim().isNotEmpty) 'search': query.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      },
    );
    final items = extractListFromResponse(response);
    return items.map(orderFromApi).toList();
  }

  @override
  Future<OrderEntity?> getOrderById(String id) async {
    if (id.trim().isEmpty) return null;
    final response = await _apiClient.getJson('orders/$id');
    final data = response['data'];
    if (data is Map<String, dynamic>) return orderFromApi(data);
    if (data is Map) return orderFromApi(data.cast<String, dynamic>());
    return null;
  }

  @override
  Future<OrderEntity> createOrder({
    required String clientId,
    required String fromLocation,
    required String toLocation,
    required double revenueExpected,
    required double vendorCost,
    double companyOtherCost = 0,
    String currency = 'SAR',
    String? financialNotes,
    String? orderNo,
    String status = 'draft',
    String? orderDate,
    String? notes,
  }) async {
    final response = await _apiClient.postJson(
      'orders',
      body: {
        'client_id': clientId,
        'from_location': fromLocation,
        'to_location': toLocation,
        'revenue_expected': revenueExpected,
        'vendor_cost': vendorCost,
        'company_other_cost': companyOtherCost,
        'currency': currency,
        if (financialNotes != null && financialNotes.isNotEmpty)
          'financial_notes': financialNotes,
        if (orderNo != null && orderNo.isNotEmpty) 'order_no': orderNo,
        'status': status,
        if (orderDate != null && orderDate.isNotEmpty) 'order_date': orderDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) return orderFromApi(data);
    if (data is Map) return orderFromApi(data.cast<String, dynamic>());
    throw Exception('Invalid create order response');
  }

  @override
  Future<OrderEntity> updateOrder(
    String id, {
    String? clientId,
    String? fromLocation,
    String? toLocation,
    double? revenueExpected,
    double? vendorCost,
    double? companyOtherCost,
    String? currency,
    String? financialNotes,
    String? orderNo,
    String? status,
    String? orderDate,
    String? notes,
  }) async {
    final response = await _apiClient.putJson(
      'orders/$id',
      body: {
        if (clientId != null) 'client_id': clientId.isEmpty ? null : clientId,
        if (fromLocation case final value) 'from_location': value,
        if (toLocation case final value) 'to_location': value,
        if (revenueExpected case final value) 'revenue_expected': value,
        if (vendorCost case final value) 'vendor_cost': value,
        if (companyOtherCost case final value) 'company_other_cost': value,
        if (currency case final value) 'currency': value,
        if (financialNotes case final value) 'financial_notes': value,
        if (orderNo case final value) 'order_no': value,
        if (status case final value) 'status': value,
        if (orderDate case final value) 'order_date': value,
        if (notes case final value) 'notes': value,
      },
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) return orderFromApi(data);
    if (data is Map) return orderFromApi(data.cast<String, dynamic>());
    throw Exception('Invalid update order response');
  }

  @override
  Future<void> deleteOrder(String id) async {
    await _apiClient.deleteJson('orders/$id');
  }
}
