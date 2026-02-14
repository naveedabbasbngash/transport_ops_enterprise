import 'package:flutter_riverpod/legacy.dart';

import '../../../shared/providers/client_repository_provider.dart';
import '../domain/repositories/client_repository.dart';
import 'client_state.dart';

class ClientViewModel extends StateNotifier<ClientState> {
  final ClientRepository _repository;

  ClientViewModel(this._repository) : super(ClientState.initial()) {
    loadClients();
  }

  Future<void> loadClients() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final clients = await _repository.getClients(
        status: state.status,
        search: state.search,
      );
      state = state.copyWith(isLoading: false, clients: clients, error: null);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load clients.',
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
    await loadClients();
  }

  Future<void> createClient({
    required String name,
    String? status,
    String? externalRef,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.createClient(
        name: name,
        status: status,
        externalRef: externalRef,
      );
      await loadClients();
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to create client.',
      );
    }
  }
}

final clientViewModelProvider =
    StateNotifierProvider<ClientViewModel, ClientState>(
      (ref) => ClientViewModel(ref.watch(clientRepositoryProvider)),
    );
