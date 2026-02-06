import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../features/expenses/data/expense_repository_impl.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import 'api_client_provider.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExpenseRepositoryImpl(apiClient);
});
