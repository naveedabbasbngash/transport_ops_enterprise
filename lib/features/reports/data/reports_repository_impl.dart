import '../../imports/data/import_local_store.dart';
import '../../imports/domain/entities/import_row_entity.dart';
import '../../trips/data/trip_local_store.dart';
import '../../trips/domain/entities/trip_entity.dart';
import '../domain/entities/report_models.dart';
import '../domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final TripLocalStore _tripLocalStore;
  final ImportLocalStore _importLocalStore;

  const ReportsRepositoryImpl({
    required TripLocalStore tripLocalStore,
    required ImportLocalStore importLocalStore,
  })  : _tripLocalStore = tripLocalStore,
        _importLocalStore = importLocalStore;

  @override
  Future<DailyReport> getDailyReport(DateTime date) async {
    final trips = await _tripLocalStore.getTrips();
    final dailyTrips = trips.where((trip) {
      final tripDate = _parseTripDate(
        raw: trip.tripDate,
        reportingMonth: trip.reportingMonth,
      );
      return tripDate != null &&
          tripDate.year == date.year &&
          tripDate.month == date.month &&
          tripDate.day == date.day;
    }).toList();

    return DailyReport(
      date: DateTime(date.year, date.month, date.day),
      totals: _totals(dailyTrips),
      topClients: _topMetrics(
        dailyTrips.map((trip) => trip.clientName).toList(),
      ),
      topRoutes: _topMetrics(
        dailyTrips
            .map((trip) => '${trip.fromLocation} -> ${trip.toLocation}')
            .toList(),
      ),
    );
  }

  @override
  Future<MonthlyComparisonReport> getMonthlyComparisonReport(
    DateTime month,
  ) async {
    final trips = await _tripLocalStore.getTrips();
    final currentMonthTrips = <TripEntity>[];
    final previousMonthTrips = <TripEntity>[];
    final previousMonth = DateTime(month.year, month.month - 1, 1);

    for (final trip in trips) {
      final parsedDate = _parseTripDate(
        raw: trip.tripDate,
        reportingMonth: trip.reportingMonth,
      );
      if (parsedDate == null) continue;

      final reportingMonth = _parseReportingMonth(trip.reportingMonth);
      final monthMatch = reportingMonth != null
          ? (reportingMonth.year == month.year &&
              reportingMonth.month == month.month)
          : (parsedDate.year == month.year && parsedDate.month == month.month);
      if (monthMatch) {
        currentMonthTrips.add(trip);
      } else {
        final previousMonthMatch = reportingMonth != null
            ? (reportingMonth.year == previousMonth.year &&
                reportingMonth.month == previousMonth.month)
            : (parsedDate.year == previousMonth.year &&
                parsedDate.month == previousMonth.month);
        if (!previousMonthMatch) continue;
        previousMonthTrips.add(trip);
      }
    }

    return MonthlyComparisonReport(
      month: DateTime(month.year, month.month, 1),
      currentMonthTotals: _totals(currentMonthTrips),
      previousMonthTotals: _totals(previousMonthTrips),
    );
  }

  @override
  Future<ReportDataQuality> getLatestDataQuality() async {
    final history = await _importLocalStore.getImportHistory();
    if (history.isEmpty) return ReportDataQuality.zero;

    final latest = history.first;
    var updatedNotApplied = 0;
    var needsReview = 0;
    var errorRows = 0;

    for (final row in latest.rows) {
      if (row.status == ImportRowStatus.updatedNotApplied) {
        updatedNotApplied++;
      } else if (row.status == ImportRowStatus.needsReview) {
        needsReview++;
      } else if (row.status == ImportRowStatus.error) {
        errorRows++;
      }
    }

    return ReportDataQuality(
      updatedNotApplied: updatedNotApplied,
      needsReview: needsReview,
      errorRows: errorRows,
    );
  }

  @override
  Future<List<TripEntity>> getAllTrips() {
    return _tripLocalStore.getTrips();
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

  List<TopMetric> _topMetrics(List<String> values) {
    final counts = <String, int>{};
    for (final value in values) {
      final key = value.trim();
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .take(5)
        .map((entry) => TopMetric(label: entry.key, count: entry.value))
        .toList();
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
