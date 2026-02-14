import '../../../core/network/api_client.dart';
import '../../../core/network/api_list_parser.dart';

class DashboardApi {
  final ApiClient _apiClient;

  const DashboardApi(this._apiClient);

  Future<Map<String, dynamic>> getTripsPage({
    int page = 1,
    String? fromDate,
    String? toDate,
  }) {
    return _apiClient.getJson(
      'trips',
      query: {
        'page': page,
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
      },
    );
  }

  Future<Map<String, dynamic>> getExpensesPage({
    int page = 1,
    String? fromDate,
    String? toDate,
  }) {
    return _apiClient.getJson(
      'expenses',
      query: {
        'page': page,
        if (fromDate != null && fromDate.isNotEmpty) 'from_date': fromDate,
        if (toDate != null && toDate.isNotEmpty) 'to_date': toDate,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final response = await _apiClient.getJson('clients');
    return extractListFromResponse(response);
  }

  Future<List<Map<String, dynamic>>> getProviders() async {
    final response = await _apiClient.getJson('vendors');
    return extractListFromResponse(response);
  }

  Future<List<Map<String, dynamic>>> getDrivers() async {
    final response = await _apiClient.getJson('drivers');
    return extractListFromResponse(response);
  }

  Future<List<Map<String, dynamic>>> getTrucks() async {
    final response = await _apiClient.getJson('trucks');
    return extractListFromResponse(response);
  }
}
