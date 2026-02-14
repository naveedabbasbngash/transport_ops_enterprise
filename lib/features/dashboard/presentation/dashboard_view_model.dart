import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;

import '../../../shared/providers/api_client_provider.dart';
import '../data/dashboard_api.dart';
import '../data/dashboard_repository_impl.dart';
import '../domain/entities/dashboard_period.dart';
import '../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRepositoryImpl(DashboardApi(apiClient));
});

class DashboardViewModel extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardViewModel(this._repository) : super(DashboardState.initial()) {
    loadSummary();
  }

  Future<void> loadSummary() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final summary = await _repository.getSummary(period: state.period);
      state = state.copyWith(
        isLoading: false,
        summary: summary,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load dashboard data.',
      );
    }
  }

  Future<void> setPeriod(DashboardPeriod period) async {
    if (period == state.period) return;
    state = state.copyWith(period: period);
    await loadSummary();
  }
}

final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>(
      (ref) => DashboardViewModel(ref.watch(dashboardRepositoryProvider)),
    );
