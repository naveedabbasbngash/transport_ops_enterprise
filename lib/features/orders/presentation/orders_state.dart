import '../domain/entities/order_entity.dart';

class OrdersState {
  final bool isLoading;
  final bool isSubmitting;
  final List<OrderEntity> orders;
  final String query;
  final String statusFilter;
  final String? error;

  const OrdersState({
    required this.isLoading,
    this.isSubmitting = false,
    this.orders = const [],
    this.query = '',
    this.statusFilter = 'all',
    this.error,
  });

  factory OrdersState.initial() => const OrdersState(isLoading: false);

  OrdersState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<OrderEntity>? orders,
    String? query,
    String? statusFilter,
    Object? error = _sentinel,
  }) {
    return OrdersState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      orders: orders ?? this.orders,
      query: query ?? this.query,
      statusFilter: statusFilter ?? this.statusFilter,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}
