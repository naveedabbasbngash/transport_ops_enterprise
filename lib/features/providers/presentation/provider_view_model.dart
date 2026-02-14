import 'package:flutter_riverpod/legacy.dart';

import '../../../shared/providers/provider_repository_provider.dart';
import '../domain/repositories/provider_repository.dart';
import 'provider_state.dart';

class ProviderViewModel extends StateNotifier<ProviderState> {
  final ProviderRepository _repository;

  ProviderViewModel(this._repository) : super(ProviderState.initial()) {
    loadProviders();
  }

  Future<void> loadProviders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final providers = await _repository.getProviders(
        status: state.status,
        search: state.search,
      );
      state = state.copyWith(
        isLoading: false,
        providers: providers,
        error: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load providers.',
      );
    }
  }

  void updateSearch(String value) {
    state = state.copyWith(search: value);
  }

  void updateStatus(String value) {
    state = state.copyWith(status: value);
  }

  Future<void> applyFilters() async {
    await loadProviders();
  }

  Future<void> createProvider({
    required String name,
    required String type,
    String? status,
    String? phone,
    String? externalRef,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createProvider(
        name: name,
        type: type,
        status: status,
        phone: phone,
        externalRef: externalRef,
        notes: notes,
      );
      await loadProviders();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to create provider.',
      );
    }
  }
}

final providerViewModelProvider =
    StateNotifierProvider<ProviderViewModel, ProviderState>(
      (ref) => ProviderViewModel(ref.watch(providerRepositoryProvider)),
    );
