import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/trips/data/location_repository_impl.dart';
import '../../features/trips/domain/repositories/location_repository.dart';
import 'api_client_provider.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LocationRepositoryImpl(apiClient);
});

