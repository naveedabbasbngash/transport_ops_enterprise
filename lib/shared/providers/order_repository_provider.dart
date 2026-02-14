import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/orders/data/order_repository_impl.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import 'api_client_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderRepositoryImpl(apiClient);
});
