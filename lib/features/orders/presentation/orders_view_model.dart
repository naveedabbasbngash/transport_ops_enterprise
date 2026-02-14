import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../features/clients/domain/entities/client_entity.dart';
import '../../../features/clients/domain/repositories/client_repository.dart';
import '../../../shared/providers/client_repository_provider.dart';
import '../../../shared/providers/order_repository_provider.dart';
import '../domain/entities/order_entity.dart';
import '../domain/repositories/order_repository.dart';
import 'orders_state.dart';

final ordersViewModelProvider =
    StateNotifierProvider<OrdersViewModel, OrdersState>((ref) {
      return OrdersViewModel(
        orderRepository: ref.watch(orderRepositoryProvider),
        clientRepository: ref.read(clientRepositoryProvider),
      );
    });

class OrdersViewModel extends StateNotifier<OrdersState> {
  OrdersViewModel({
    required OrderRepository orderRepository,
    required ClientRepository clientRepository,
  }) : _orderRepository = orderRepository,
       _clientRepository = clientRepository,
       super(OrdersState.initial()) {
    loadOrders();
  }

  final OrderRepository _orderRepository;
  final ClientRepository _clientRepository;

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final status = state.statusFilter == 'all' ? null : state.statusFilter;
      final orders = await _orderRepository.getOrders(
        query: state.query,
        status: status,
      );
      state = state.copyWith(isLoading: false, orders: orders);
    } catch (e) {
      debugPrint('Failed to load orders: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to load orders.');
    }
  }

  Future<void> onQueryChanged(String value) async {
    state = state.copyWith(query: value);
    await loadOrders();
  }

  Future<void> setStatusFilter(String value) async {
    state = state.copyWith(statusFilter: value);
    await loadOrders();
  }

  Future<List<ClientEntity>> getClients({
    String status = 'active',
    String search = '',
  }) {
    return _clientRepository.getClients(status: status, search: search);
  }

  Future<OrderEntity?> getOrderById(String id) {
    return _orderRepository.getOrderById(id);
  }

  Future<bool> createOrder({
    required String clientId,
    required String fromLocation,
    required String toLocation,
    required double revenueExpected,
    required double vendorCost,
    double companyOtherCost = 0,
    String currency = 'SAR',
    String? financialNotes,
    String? orderNo,
    required String status,
    String? orderDate,
    String? notes,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _orderRepository.createOrder(
        clientId: clientId,
        fromLocation: fromLocation,
        toLocation: toLocation,
        revenueExpected: revenueExpected,
        vendorCost: vendorCost,
        companyOtherCost: companyOtherCost,
        currency: currency,
        financialNotes: financialNotes,
        orderNo: orderNo,
        status: status,
        orderDate: orderDate,
        notes: notes,
      );
      state = state.copyWith(isSubmitting: false);
      await loadOrders();
      return true;
    } catch (e) {
      debugPrint('Create order failed: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to create order.',
      );
      return false;
    }
  }

  Future<bool> updateOrder(
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
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _orderRepository.updateOrder(
        id,
        clientId: clientId,
        fromLocation: fromLocation,
        toLocation: toLocation,
        revenueExpected: revenueExpected,
        vendorCost: vendorCost,
        companyOtherCost: companyOtherCost,
        currency: currency,
        financialNotes: financialNotes,
        orderNo: orderNo,
        status: status,
        orderDate: orderDate,
        notes: notes,
      );
      state = state.copyWith(isSubmitting: false);
      await loadOrders();
      return true;
    } catch (e) {
      debugPrint('Update order failed: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to update order.',
      );
      return false;
    }
  }

  Future<bool> deleteOrder(String id) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _orderRepository.deleteOrder(id);
      state = state.copyWith(isSubmitting: false);
      await loadOrders();
      return true;
    } catch (e) {
      debugPrint('Delete order failed: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to delete order.',
      );
      return false;
    }
  }
}
