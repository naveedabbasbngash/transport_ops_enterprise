import '../entities/order_entity.dart';

abstract class OrderRepository {
  Future<List<OrderEntity>> getOrders({String query = '', String? status});
  Future<OrderEntity?> getOrderById(String id);
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
  });
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
  });
  Future<void> deleteOrder(String id);
}
