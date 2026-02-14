import '../domain/entities/client_entity.dart';

class ClientState {
  final bool isLoading;
  final String? error;
  final List<ClientEntity> clients;
  final String search;
  final String status;

  const ClientState({
    required this.isLoading,
    required this.clients,
    required this.search,
    required this.status,
    this.error,
  });

  factory ClientState.initial() {
    return const ClientState(
      isLoading: false,
      clients: [],
      search: '',
      status: 'active',
    );
  }

  ClientState copyWith({
    bool? isLoading,
    List<ClientEntity>? clients,
    String? search,
    String? status,
    String? error,
  }) {
    return ClientState(
      isLoading: isLoading ?? this.isLoading,
      clients: clients ?? this.clients,
      search: search ?? this.search,
      status: status ?? this.status,
      error: error,
    );
  }
}
