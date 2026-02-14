import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/providers/data/provider_repository_impl.dart';
import '../../features/providers/domain/repositories/provider_repository.dart';
import 'api_client_provider.dart';

final providerRepositoryProvider = Provider<ProviderRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProviderRepositoryImpl(apiClient);
});
