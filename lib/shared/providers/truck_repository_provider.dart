import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../features/trucks/data/truck_repository_impl.dart';
import '../../features/trucks/domain/repositories/truck_repository.dart';
import 'api_client_provider.dart';

final truckRepositoryProvider = Provider<TruckRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TruckRepositoryImpl(apiClient);
});
