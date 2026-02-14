import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/clients/data/client_repository_impl.dart';
import '../../features/clients/domain/repositories/client_repository.dart';
import 'api_client_provider.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ClientRepositoryImpl(apiClient);
});
