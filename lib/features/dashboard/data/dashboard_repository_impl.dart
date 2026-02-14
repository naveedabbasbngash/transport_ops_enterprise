import '../../../core/network/api_list_parser.dart';
import '../domain/entities/dashboard_period.dart';
import '../domain/entities/dashboard_summary.dart';
import '../domain/repositories/dashboard_repository.dart';
import 'dashboard_api.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardApi _api;

  const DashboardRepositoryImpl(this._api);

  @override
  Future<DashboardSummary> getSummary({required DashboardPeriod period}) async {
    final range = _resolveDateRange(period);
    final results = await Future.wait<dynamic>([
      _api.getTripsPage(page: 1, fromDate: range.$1, toDate: range.$2),
      _api.getExpensesPage(page: 1, fromDate: range.$1, toDate: range.$2),
      _api.getClients(),
      _api.getProviders(),
      _api.getDrivers(),
      _api.getTrucks(),
    ]);

    final tripsBody = _asMap(results[0]);
    final expensesBody = _asMap(results[1]);
    final clients = _asList(results[2]);
    final providers = _asList(results[3]);
    final drivers = _asList(results[4]);
    final trucks = _asList(results[5]);

    final tripItems = extractListFromResponse(tripsBody);
    final expenseItems = extractListFromResponse(expensesBody);

    final totalTrips = _extractPaginationTotal(tripsBody) ?? tripItems.length;
    final totalExpenses =
        _extractPaginationTotal(expensesBody) ?? expenseItems.length;

    final activeDrivers = drivers
        .where((item) => _statusOf(item) == 'active')
        .length;
    final activeTrucks = trucks
        .where((item) => _statusOf(item) == 'active')
        .length;

    final recentTrips = tripItems.take(5).map(_toRecentTrip).toList();
    final recentRevenue = recentTrips.fold<double>(
      0,
      (sum, trip) => sum + trip.revenue,
    );

    return DashboardSummary(
      totalTrips: totalTrips,
      totalClients: clients.length,
      totalProviders: providers.length,
      totalDrivers: drivers.length,
      activeDrivers: activeDrivers,
      totalTrucks: trucks.length,
      activeTrucks: activeTrucks,
      totalExpenses: totalExpenses,
      recentRevenue: recentRevenue,
      recentTrips: recentTrips,
      refreshedAt: DateTime.now(),
    );
  }

  (String, String) _resolveDateRange(DashboardPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime from;
    switch (period) {
      case DashboardPeriod.today:
        from = today;
        break;
      case DashboardPeriod.last7Days:
        from = today.subtract(const Duration(days: 6));
        break;
      case DashboardPeriod.last30Days:
        from = today.subtract(const Duration(days: 29));
        break;
    }
    return (_ymd(from), _ymd(today));
  }

  String _ymd(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  DashboardRecentTrip _toRecentTrip(Map<String, dynamic> map) {
    final from = _text(map['from_location']);
    final to = _text(map['to_location']);
    final route = from.isNotEmpty || to.isNotEmpty
        ? '$from -> $to'
        : (_text(map['reference_no']).isNotEmpty
              ? _text(map['reference_no'])
              : _text(map['id']));

    final revenue = _toDouble(
      map['trip_amount'] ??
          map['revenue_expected'] ??
          _asMap(map['trip_financials'])['revenue_expected'],
    );

    return DashboardRecentTrip(
      id: _text(map['id']),
      route: route,
      date: _text(map['trip_date']),
      status: _text(map['status']).isEmpty ? 'open' : _text(map['status']),
      revenue: revenue,
    );
  }

  String _statusOf(Map<String, dynamic> item) {
    final value = _text(item['status']);
    return value.isEmpty ? 'active' : value;
  }

  int? _extractPaginationTotal(Map<String, dynamic> body) {
    final data = _asMap(body['data']);
    final pagination = _asMap(data['pagination']);
    final total = pagination['total'];
    if (total is int) return total;
    return int.tryParse(total?.toString() ?? '');
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is List<Map<String, dynamic>>) return value;
    if (value is List) {
      return value
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  String _text(Object? value) {
    return (value ?? '').toString().trim();
  }

  double _toDouble(Object? value) {
    if (value == null) return 0;
    final cleaned = value.toString().replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
