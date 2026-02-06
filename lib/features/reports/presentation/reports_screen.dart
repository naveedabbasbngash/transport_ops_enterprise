import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/services/clipboard_service.dart';
import '../../trips/domain/entities/trip_entity.dart';
import '../domain/entities/report_models.dart';
import 'reports_state.dart';
import 'reports_view_model.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsViewModelProvider);
    final vm = ref.read(reportsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isLoading ? null : vm.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1000;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _HeaderPanel(state: state),
                        const SizedBox(height: 12),
                        _FilterPanel(
                          state: state,
                          vm: vm,
                          isDesktop: isDesktop,
                        ),
                        const SizedBox(height: 12),
                        _KpiGrid(state: state),
                        const SizedBox(height: 12),
                        _DataQualityBanner(quality: state.dataQuality),
                        const SizedBox(height: 12),
                        _ActionRow(vm: vm),
                        const SizedBox(height: 12),
                        _TripsSection(
                          trips: state.filteredTrips,
                          isDesktop: isDesktop,
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            state.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TransportOps Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Analyze daily, monthly, and range performance with operational filters.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Now: ${formatter.format(DateTime.now())}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({
    required this.state,
    required this.vm,
    required this.isDesktop,
  });

  final ReportsState state;
  final ReportsViewModel vm;
  final bool isDesktop;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.state.query);
  }

  @override
  void didUpdateWidget(covariant _FilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.query != _queryController.text) {
      _queryController.value = TextEditingValue(
        text: widget.state.query,
        selection: TextSelection.collapsed(offset: widget.state.query.length),
      );
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final vm = widget.vm;
    final isDesktop = widget.isDesktop;

    final fields = <Widget>[
      SizedBox(
        width: isDesktop ? 430 : double.infinity,
        child: SegmentedButton<ReportPeriod>(
          segments: const [
            ButtonSegment(value: ReportPeriod.today, label: Text('Today')),
            ButtonSegment(value: ReportPeriod.day, label: Text('Day')),
            ButtonSegment(value: ReportPeriod.month, label: Text('Month')),
            ButtonSegment(value: ReportPeriod.range, label: Text('Range')),
          ],
          selected: {state.period},
          onSelectionChanged: (selection) {
            vm.setPeriod(selection.first);
          },
        ),
      ),
      _PeriodPicker(state: state, vm: vm),
      SizedBox(
        width: isDesktop ? 340 : double.infinity,
        child: TextField(
          controller: _queryController,
          onChanged: vm.setQuery,
          decoration: const InputDecoration(
            labelText: 'Search',
            hintText: 'Client, plate, waybill, route, remarks',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
      ),
      _FilterDropdown(
        width: isDesktop ? 230 : double.infinity,
        label: 'Client',
        value: state.selectedClient,
        options: state.availableClients,
        onChanged: vm.setClient,
      ),
      _FilterDropdown(
        width: isDesktop ? 220 : double.infinity,
        label: 'Plate',
        value: state.selectedPlate,
        options: state.availablePlates,
        onChanged: vm.setPlate,
      ),
      _FilterDropdown(
        width: isDesktop ? 320 : double.infinity,
        label: 'Route',
        value: state.selectedRoute,
        options: state.availableRoutes,
        onChanged: vm.setRoute,
      ),
      SizedBox(
        width: isDesktop ? 180 : double.infinity,
        child: OutlinedButton.icon(
          onPressed: vm.clearFilters,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Clear Filters'),
        ),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: fields,
        ),
      ),
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.state, required this.vm});

  final ReportsState state;
  final ReportsViewModel vm;

  @override
  Widget build(BuildContext context) {
    switch (state.period) {
      case ReportPeriod.today:
        return Chip(
          avatar: const Icon(Icons.today_rounded, size: 18),
          label: Text(DateFormat('yyyy-MM-dd').format(DateTime.now())),
        );
      case ReportPeriod.day:
        return OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              await vm.setDate(picked);
            }
          },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(DateFormat('yyyy-MM-dd').format(state.selectedDate)),
        );
      case ReportPeriod.month:
        return OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.selectedMonth,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              await vm.setMonth(DateTime(picked.year, picked.month, 1));
            }
          },
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(DateFormat('yyyy-MM').format(state.selectedMonth)),
        );
      case ReportPeriod.range:
        return OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              initialDateRange: state.selectedRange,
            );
            if (picked != null) {
              await vm.setRange(picked);
            }
          },
          icon: const Icon(Icons.date_range_outlined),
          label: Text(
            '${DateFormat('yyyy-MM-dd').format(state.selectedRange.start)} - '
            '${DateFormat('yyyy-MM-dd').format(state.selectedRange.end)}',
          ),
        );
    }
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.width,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final double width;
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = value != null && options.contains(value) ? value : null;
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-${safeValue ?? 'all'}'),
        initialValue: safeValue,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('All'),
          ),
          ...options.map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiCard(title: 'Today', totals: state.todayTotals),
      _KpiCard(title: 'Selected Day', totals: state.selectedDayTotals),
      _KpiCard(title: 'Selected Month', totals: state.selectedMonthTotals),
      _KpiCard(title: 'Filtered', totals: state.filteredTotals, emphasized: true),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards,
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.totals,
    this.emphasized = false,
  });

  final String title;
  final ReportTotals totals;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0);
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 290,
      child: Card(
        color: emphasized ? colorScheme.secondaryContainer : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text('Trips: ${totals.tripCount}'),
              Text('Revenue: ${money.format(totals.revenue)}'),
              Text('Vendor: ${money.format(totals.vendorCost)}'),
              Text('Other: ${money.format(totals.otherCost)}'),
              const Divider(),
              Text(
                'Profit: ${money.format(totals.profit)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataQualityBanner extends StatelessWidget {
  const _DataQualityBanner({required this.quality});

  final ReportDataQuality quality;

  @override
  Widget build(BuildContext context) {
    final hasRisk = quality.updatedNotApplied > 0 ||
        quality.needsReview > 0 ||
        quality.errorRows > 0;

    return Card(
      color: hasRisk
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              hasRisk ? Icons.warning_amber_rounded : Icons.verified_outlined,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Data Quality: updated-not-applied ${quality.updatedNotApplied} | '
                'needs-review ${quality.needsReview} | errors ${quality.errorRows}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends ConsumerWidget {
  const _ActionRow({required this.vm});

  final ReportsViewModel vm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await ClipboardService().copyText(vm.buildSummaryText());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Summary copied to clipboard')),
                );
              }
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy Summary'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: () async {
              final text = vm.buildSummaryText();
              final uri = Uri.parse(
                'https://wa.me/?text=${Uri.encodeComponent(text)}',
              );
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share WhatsApp'),
          ),
        ),
      ],
    );
  }
}

class _TripsSection extends StatelessWidget {
  const _TripsSection({
    required this.trips,
    required this.isDesktop,
  });

  final List<TripEntity> trips;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Rows (${trips.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (trips.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No trips for current filters.')),
              )
            else if (isDesktop)
              _TripsDataTable(trips: trips)
            else
              _TripsMobileList(trips: trips),
          ],
        ),
      ),
    );
  }
}

class _TripsDataTable extends StatelessWidget {
  const _TripsDataTable({required this.trips});

  final List<TripEntity> trips;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Client')),
          DataColumn(label: Text('Route')),
          DataColumn(label: Text('Waybill')),
          DataColumn(label: Text('Plate')),
          DataColumn(label: Text('Revenue')),
          DataColumn(label: Text('Profit')),
        ],
        rows: trips.map((trip) {
          return DataRow(
            cells: [
              DataCell(Text(trip.tripDate)),
              DataCell(Text(trip.clientName)),
              DataCell(Text('${trip.fromLocation} -> ${trip.toLocation}')),
              DataCell(Text(trip.waybillNo.isEmpty ? '-' : trip.waybillNo)),
              DataCell(Text(trip.plateNo)),
              DataCell(Text(money.format(trip.tripAmount))),
              DataCell(Text(money.format(trip.profit))),
            ],
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _TripsMobileList extends StatelessWidget {
  const _TripsMobileList({required this.trips});

  final List<TripEntity> trips;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'SAR ', decimalDigits: 0);

    return Column(
      children: [
        for (final trip in trips)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${trip.fromLocation} -> ${trip.toLocation}'),
              subtitle: Text(
                '${trip.tripDate} • ${trip.clientName}\n'
                'Waybill: ${trip.waybillNo.isEmpty ? '-' : trip.waybillNo} • Plate: ${trip.plateNo}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(money.format(trip.tripAmount)),
                  Text(
                    money.format(trip.profit),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
