import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../imports/data/import_local_store.dart';
import '../../trips/data/trip_local_store.dart';
import '../../trips/domain/entities/trip_entity.dart';
import '../data/reports_repository_impl.dart';
import '../domain/entities/report_models.dart';
import '../domain/repositories/reports_repository.dart';
import '../domain/usecases/get_all_report_trips.dart';
import '../domain/usecases/get_daily_report.dart';
import '../domain/usecases/get_latest_data_quality.dart';
import '../domain/usecases/get_monthly_comparison_report.dart';
import 'reports_state.dart';

final _tripLocalStoreProvider = Provider<TripLocalStore>((ref) {
  return TripLocalStore();
});

final _importLocalStoreProvider = Provider<ImportLocalStore>((ref) {
  return ImportLocalStore();
});

final _reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepositoryImpl(
    tripLocalStore: ref.watch(_tripLocalStoreProvider),
    importLocalStore: ref.watch(_importLocalStoreProvider),
  );
});

final _getDailyReportProvider = Provider<GetDailyReport>((ref) {
  return GetDailyReport(ref.watch(_reportsRepositoryProvider));
});

final _getMonthlyComparisonProvider = Provider<GetMonthlyComparisonReport>((ref) {
  return GetMonthlyComparisonReport(ref.watch(_reportsRepositoryProvider));
});

final _getLatestDataQualityProvider = Provider<GetLatestDataQuality>((ref) {
  return GetLatestDataQuality(ref.watch(_reportsRepositoryProvider));
});

final _getAllReportTripsProvider = Provider<GetAllReportTrips>((ref) {
  return GetAllReportTrips(ref.watch(_reportsRepositoryProvider));
});

final reportsViewModelProvider =
    StateNotifierProvider<ReportsViewModel, ReportsState>(
  (ref) => ReportsViewModel(
    getDailyReport: ref.watch(_getDailyReportProvider),
    getMonthlyComparisonReport: ref.watch(_getMonthlyComparisonProvider),
    getLatestDataQuality: ref.watch(_getLatestDataQualityProvider),
    getAllReportTrips: ref.watch(_getAllReportTripsProvider),
  ),
);

class ReportsViewModel extends StateNotifier<ReportsState> {
  ReportsViewModel({
    required GetDailyReport getDailyReport,
    required GetMonthlyComparisonReport getMonthlyComparisonReport,
    required GetLatestDataQuality getLatestDataQuality,
    required GetAllReportTrips getAllReportTrips,
  })  : _getDailyReport = getDailyReport,
        _getMonthlyComparisonReport = getMonthlyComparisonReport,
        _getLatestDataQuality = getLatestDataQuality,
        _getAllReportTrips = getAllReportTrips,
        super(ReportsState.initial()) {
    refresh();
  }

  final GetDailyReport _getDailyReport;
  final GetMonthlyComparisonReport _getMonthlyComparisonReport;
  final GetLatestDataQuality _getLatestDataQuality;
  final GetAllReportTrips _getAllReportTrips;

  List<TripEntity> _allTrips = const <TripEntity>[];

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      final quality = await _getLatestDataQuality();
      final todayDaily = await _getDailyReport(todayDate);
      final selectedDaily = await _getDailyReport(state.selectedDate);
      final monthly = await _getMonthlyComparisonReport(state.selectedMonth);
      _allTrips = await _getAllReportTrips();

      final clients = _distinct(
        _allTrips.map((trip) => trip.clientName),
      );
      final plates = _distinct(
        _allTrips.map((trip) => trip.plateNo),
      );
      final routes = _distinct(
        _allTrips.map((trip) => '${trip.fromLocation} -> ${trip.toLocation}'),
      );

      state = state.copyWith(
        isLoading: false,
        todayTotals: todayDaily.totals,
        selectedDayTotals: selectedDaily.totals,
        selectedMonthTotals: monthly.currentMonthTotals,
        monthlyReport: monthly,
        dataQuality: quality,
        availableClients: clients,
        availablePlates: plates,
        availableRoutes: routes,
        error: null,
      );

      _applyFilters();
    } catch (e) {
      debugPrint('Failed to load reports: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load reports.',
      );
    }
  }

  Future<void> setPeriod(ReportPeriod period) async {
    state = state.copyWith(period: period);
    _applyFilters();
  }

  Future<void> setDate(DateTime date) async {
    state = state.copyWith(
      selectedDate: DateTime(date.year, date.month, date.day),
    );
    await refresh();
  }

  Future<void> setMonth(DateTime month) async {
    state = state.copyWith(
      selectedMonth: DateTime(month.year, month.month, 1),
    );
    await refresh();
  }

  Future<void> setRange(DateTimeRange range) async {
    state = state.copyWith(
      selectedRange: range,
    );
    _applyFilters();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    _applyFilters();
  }

  void setClient(String? client) {
    state = state.copyWith(selectedClient: client);
    _applyFilters();
  }

  void setPlate(String? plate) {
    state = state.copyWith(selectedPlate: plate);
    _applyFilters();
  }

  void setRoute(String? route) {
    state = state.copyWith(selectedRoute: route);
    _applyFilters();
  }

  void clearFilters() {
    state = state.copyWith(
      query: '',
      selectedClient: null,
      selectedPlate: null,
      selectedRoute: null,
    );
    _applyFilters();
  }

  String buildSummaryText() {
    final money = NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0);
    final totals = state.filteredTotals;

    return '''
TransportOps Report Summary
Period: ${_periodLabel()}

Filtered Totals:
- Trips: ${totals.tripCount}
- Revenue: ${money.format(totals.revenue)}
- Vendor Cost: ${money.format(totals.vendorCost)}
- Other Cost: ${money.format(totals.otherCost)}
- Profit: ${money.format(totals.profit)}

Baseline:
- Today Trips: ${state.todayTotals.tripCount}
- Selected Day Trips: ${state.selectedDayTotals.tripCount}
- Selected Month Trips: ${state.selectedMonthTotals.tripCount}

Data Quality:
- Updated (not applied): ${state.dataQuality.updatedNotApplied}
- Needs review: ${state.dataQuality.needsReview}
- Error rows: ${state.dataQuality.errorRows}
'''.trim();
  }

  String _periodLabel() {
    switch (state.period) {
      case ReportPeriod.today:
        return 'Today';
      case ReportPeriod.day:
        return DateFormat('yyyy-MM-dd').format(state.selectedDate);
      case ReportPeriod.month:
        return DateFormat('yyyy-MM').format(state.selectedMonth);
      case ReportPeriod.range:
        return '${DateFormat('yyyy-MM-dd').format(state.selectedRange.start)} to '
            '${DateFormat('yyyy-MM-dd').format(state.selectedRange.end)}';
    }
  }

  void _applyFilters() {
    final lowerQuery = state.query.trim().toLowerCase();
    final filtered = <TripEntity>[];

    for (final trip in _allTrips) {
      final date = _parseTripDate(
        raw: trip.tripDate,
        reportingMonth: trip.reportingMonth,
      );
      if (date == null) continue;

      if (!_matchesPeriod(date: date, trip: trip)) continue;
      if (state.selectedClient != null && trip.clientName != state.selectedClient) {
        continue;
      }
      if (state.selectedPlate != null && trip.plateNo != state.selectedPlate) {
        continue;
      }
      final routeLabel = '${trip.fromLocation} -> ${trip.toLocation}';
      if (state.selectedRoute != null && routeLabel != state.selectedRoute) {
        continue;
      }
      if (lowerQuery.isNotEmpty) {
        final haystack = [
          trip.clientName,
          trip.tripDate,
          trip.waybillNo,
          trip.plateNo,
          trip.fromLocation,
          trip.toLocation,
          trip.driverName,
          trip.vehicleType,
          trip.remarks,
        ].join(' ').toLowerCase();
        if (!haystack.contains(lowerQuery)) continue;
      }

      filtered.add(trip);
    }

    state = state.copyWith(
      filteredTrips: filtered,
      filteredTotals: _totals(filtered),
    );
  }

  bool _matchesPeriod({
    required DateTime date,
    required TripEntity trip,
  }) {
    switch (state.period) {
      case ReportPeriod.today:
        final now = DateTime.now();
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case ReportPeriod.day:
        return date.year == state.selectedDate.year &&
            date.month == state.selectedDate.month &&
            date.day == state.selectedDate.day;
      case ReportPeriod.month:
        final parsedReportingMonth = _parseReportingMonth(trip.reportingMonth);
        if (parsedReportingMonth != null) {
          return parsedReportingMonth.year == state.selectedMonth.year &&
              parsedReportingMonth.month == state.selectedMonth.month;
        }
        return date.year == state.selectedMonth.year &&
            date.month == state.selectedMonth.month;
      case ReportPeriod.range:
        final start = DateTime(
          state.selectedRange.start.year,
          state.selectedRange.start.month,
          state.selectedRange.start.day,
        );
        final end = DateTime(
          state.selectedRange.end.year,
          state.selectedRange.end.month,
          state.selectedRange.end.day,
          23,
          59,
          59,
        );
        return !date.isBefore(start) && !date.isAfter(end);
    }
  }

  ReportTotals _totals(List<TripEntity> trips) {
    var revenue = 0.0;
    var vendorCost = 0.0;
    var otherCost = 0.0;

    for (final trip in trips) {
      revenue += trip.tripAmount;
      vendorCost += trip.vendorCost;
      otherCost += trip.companyOtherCost;
    }

    return ReportTotals(
      tripCount: trips.length,
      revenue: revenue,
      vendorCost: vendorCost,
      otherCost: otherCost,
      profit: revenue - vendorCost - otherCost,
    );
  }

  List<String> _distinct(Iterable<String> values) {
    final set = <String>{};
    for (final value in values) {
      final v = value.trim();
      if (v.isEmpty) continue;
      set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  DateTime? _parseTripDate({
    required String raw,
    required String reportingMonth,
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    final normalized = trimmed.replaceAll('/', '-');
    final parts = normalized.split('-');
    if (parts.length != 3) return null;

    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);
    if (first == null || second == null || third == null) return null;

    DateTime? dmy;
    DateTime? mdy;

    if (third >= 1900 && second >= 1 && second <= 12 && first >= 1 && first <= 31) {
      dmy = DateTime(third, second, first);
    }

    if (third >= 1900 && first >= 1 && first <= 12 && second >= 1 && second <= 31) {
      mdy = DateTime(third, first, second);
    }

    if (dmy != null && mdy == null) return dmy;
    if (mdy != null && dmy == null) return mdy;
    if (dmy == null && mdy == null) return null;

    final parsedReportingMonth = _parseReportingMonth(reportingMonth);
    if (parsedReportingMonth != null) {
      if (dmy != null &&
          dmy.year == parsedReportingMonth.year &&
          dmy.month == parsedReportingMonth.month) {
        return dmy;
      }
      if (mdy != null &&
          mdy.year == parsedReportingMonth.year &&
          mdy.month == parsedReportingMonth.month) {
        return mdy;
      }
    }

    return dmy ?? mdy;
  }

  DateTime? _parseReportingMonth(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return null;
    return DateTime(year, month, 1);
  }
}
