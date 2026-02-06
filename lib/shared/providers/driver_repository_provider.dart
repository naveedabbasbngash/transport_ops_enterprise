import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../features/drivers/data/driver_repository_impl.dart';
import '../../features/drivers/domain/repositories/driver_repository.dart';
import 'api_client_provider.dart';

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DriverRepositoryImpl(apiClient);
});
