import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../drivers/domain/entities/driver_entity.dart';
import '../../trucks/domain/entities/truck_entity.dart';
import '../../../shared/providers/driver_repository_provider.dart';
import '../../../shared/providers/truck_repository_provider.dart';
import '../../../core/constants/app_routes.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../domain/entities/expense_entity.dart';
import '../../../core/logging/expense_log_buffer.dart';
import 'expense_list_view_model.dart';
import 'expense_list_state.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final _searchController = TextEditingController();
  List<TruckEntity> _trucks = const [];
  List<DriverEntity> _drivers = const [];
  bool _loadingLookups = true;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final driverRepo = ref.read(driverRepositoryProvider);
      final truckRepo = ref.read(truckRepositoryProvider);
      final results = await Future.wait([
        driverRepo.getDrivers(),
        truckRepo.getTrucks(),
      ]);
      if (!mounted) return;
      setState(() {
        _drivers = results[0] as List<DriverEntity>;
        _trucks = results[1] as List<TruckEntity>;
        _loadingLookups = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLookups = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(expenseListViewModelProvider);
    final viewModel = ref.read(expenseListViewModelProvider.notifier);
    final expenses =
        _applySearch(viewModel.filtered, state.search, _trucks, _drivers);
    final authState = ref.watch(authViewModelProvider);
    final isReadOnly = authState.user?.isOwnerReadOnly ?? true;
    final totalAmount =
        expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final rangeLabel = _rangeLabel(state);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _MonthSelector(
              label: _monthLabel(state),
              compact: MediaQuery.of(context).size.width < 520,
              onTap: () => _pickMonth(context, viewModel, state),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.isLoading ? null : viewModel.loadExpenses,
          ),
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => _openExpenseLogs(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (isReadOnly) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Read-only account: cannot add expenses.'),
              ),
            );
            return;
          }
          await Navigator.of(context).pushNamed(AppRoutes.expenseCreate);
          if (mounted) {
            ref.read(expenseListViewModelProvider.notifier).loadExpenses();
          }
        },
        label: Text(isReadOnly ? 'Read-Only' : 'New Expense'),
        icon: Icon(isReadOnly ? Icons.lock_rounded : Icons.add_rounded),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          final isCompact = constraints.maxWidth < 700;
          final theme = Theme.of(context);
          final titleStyle = GoogleFonts.roboto(
            textStyle: theme.textTheme.headlineSmall,
            fontWeight: FontWeight.w700,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _AdmobHeader(
                  totalAmount: totalAmount,
                  expenseCount: expenses.length,
                  rangeLabel: rangeLabel,
                  titleStyle: titleStyle,
                ),
              ),
              SliverToBoxAdapter(
                child: _SearchHeader(
                  controller: _searchController,
                  filterCount: _activeFilterCount(state),
                  onChanged: (value) => viewModel.updateSearch(value),
                  onClear: () {
                    _searchController.clear();
                    viewModel.updateSearch('');
                  },
                  onOpenFilters: () {
                    _openFilterSheet(
                      context: context,
                      state: state,
                      viewModel: viewModel,
                      trucks: _trucks,
                      drivers: _drivers,
                      loadingLookups: _loadingLookups,
                    );
                  },
                ),
              ),
              if (state.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      state.error!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: _SummaryRow(
                  expenses: expenses,
                  compact: isCompact,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (state.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (expenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No expenses found for the selected filters.',
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: isWide
                      ? _ExpenseTable(
                          expenses: expenses,
                          trucks: _trucks,
                          drivers: _drivers,
                          shrinkWrap: true,
                        )
                      : _ExpenseCards(
                          expenses: expenses,
                          trucks: _trucks,
                          drivers: _drivers,
                          shrinkWrap: true,
                        ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openExpenseLogs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ExpenseLogSheet(),
    );
  }
}

void _openFilterSheet({
  required BuildContext context,
  required ExpenseListState state,
  required ExpenseListViewModel viewModel,
  required List<TruckEntity> trucks,
  required List<DriverEntity> drivers,
  required bool loadingLookups,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _FilterSheet(
      state: state,
      viewModel: viewModel,
      trucks: trucks,
      drivers: drivers,
      loadingLookups: loadingLookups,
    ),
  );
}

class _AdmobHeader extends StatelessWidget {
  final double totalAmount;
  final int expenseCount;
  final String rangeLabel;
  final TextStyle titleStyle;

  const _AdmobHeader({
    required this.totalAmount,
    required this.expenseCount,
    required this.rangeLabel,
    required this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 900;

    final amountStyle = GoogleFonts.roboto(
      textStyle: theme.textTheme.displaySmall,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      letterSpacing: -0.5,
    );

    final labelStyle = GoogleFonts.roboto(
      textStyle: theme.textTheme.bodyMedium,
      fontWeight: FontWeight.w500,
      color: Colors.white.withOpacity(0.85),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // ───────────────── BACKGROUND ─────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0B1F3A),
                    Color(0xFF0F766E),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: isWide
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _HeaderLeft(
                      titleStyle: titleStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      rangeLabel: rangeLabel,
                      expenseCount: expenseCount,
                      labelStyle: labelStyle,
                    ),
                  ),
                  const SizedBox(width: 24),
                  _HeaderRight(
                    totalAmount: totalAmount,
                    amountStyle: amountStyle,
                    labelStyle: labelStyle,
                  ),
                ],
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderLeft(
                    titleStyle: titleStyle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    rangeLabel: rangeLabel,
                    expenseCount: expenseCount,
                    labelStyle: labelStyle,
                  ),
                  const SizedBox(height: 18),
                  const Divider(
                    color: Colors.white24,
                    thickness: 1,
                  ),
                  const SizedBox(height: 14),
                  _HeaderRight(
                    totalAmount: totalAmount,
                    amountStyle: amountStyle,
                    labelStyle: labelStyle,
                  ),
                ],
              ),
            ),

            // ───────────────── GLOW ELEMENTS ─────────────────
            Positioned(
              right: -50,
              top: -70,
              child: _GlowOrb(
                size: 160,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -70,
              child: _GlowOrb(
                size: 120,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _HeaderLeft extends StatelessWidget {
  final TextStyle titleStyle;
  final String rangeLabel;
  final int expenseCount;
  final TextStyle labelStyle;

  const _HeaderLeft({
    required this.titleStyle,
    required this.rangeLabel,
    required this.expenseCount,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final subtitleStyle = labelStyle.copyWith(
      fontSize: 13,
      color: Colors.white.withOpacity(0.75),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ───────── TITLE ─────────
        Text(
          'Expense Monitor',
          style: titleStyle.copyWith(
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 6),

        // ───────── DATE RANGE ─────────
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(rangeLabel, style: subtitleStyle),
          ],
        ),

        const SizedBox(height: 20),

        // ───────── STATS CHIPS ─────────
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _HeaderChip(
              icon: Icons.receipt_long_rounded,
              label: '$expenseCount records',
            ),
            _HeaderChip(
              icon: Icons.bolt_rounded,
              label: 'Live tracking',
            ),
          ],
        ),
      ],
    );
  }
}
class _HeaderRight extends StatelessWidget {
  final double totalAmount;
  final TextStyle amountStyle;
  final TextStyle labelStyle;

  const _HeaderRight({
    required this.totalAmount,
    required this.amountStyle,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currencyStyle = labelStyle.copyWith(
      fontSize: 12,
      color: Colors.white.withOpacity(0.7),
      fontWeight: FontWeight.w500,
    );

    final valueStyle = amountStyle.copyWith(
      letterSpacing: -0.6,
      height: 1.1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ───────── LABEL ─────────
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 14,
              color: Colors.white.withOpacity(0.75),
            ),
            const SizedBox(width: 6),
            Text('Total Spend', style: labelStyle),
          ],
        ),

        const SizedBox(height: 10),

        // ───────── AMOUNT ─────────
        RichText(
          textAlign: TextAlign.end,
          text: TextSpan(
            children: [
              TextSpan(
                text: totalAmount.toStringAsFixed(2),
                style: valueStyle,
              ),
              const TextSpan(text: '  '),
              TextSpan(
                text: 'SAR',
                style: currencyStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withOpacity(0.85)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.roboto(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final int filterCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onOpenFilters;

  const _SearchHeader({
    required this.controller,
    required this.filterCount,
    required this.onChanged,
    required this.onClear,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 720;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Search expenses, truck, driver',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: onClear,
                      ),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: onOpenFilters,
            icon: const Icon(Icons.tune_rounded),
            label: Text(
              isWide && filterCount > 0
                  ? 'Filters • $filterCount'
                  : isWide
                      ? 'Filters'
                      : '$filterCount',
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final String label;
  final bool compact;
  final VoidCallback onTap;

  const _MonthSelector({
    required this.label,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return compact
        ? IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: onTap,
          )
        : TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(label),
          );
  }
}

class _FilterSheet extends StatefulWidget {
  final ExpenseListState state;
  final ExpenseListViewModel viewModel;
  final List<TruckEntity> trucks;
  final List<DriverEntity> drivers;
  final bool loadingLookups;

  const _FilterSheet({
    required this.state,
    required this.viewModel,
    required this.trucks,
    required this.drivers,
    required this.loadingLookups,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final TextEditingController _truckController;
  late final TextEditingController _driverController;
  final _truckFocus = FocusNode();
  final _driverFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _truckController =
        TextEditingController(text: widget.state.plateNo ?? '');
    _driverController =
        TextEditingController(text: widget.state.driverName ?? '');
  }

  @override
  void dispose() {
    _truckController.dispose();
    _driverController.dispose();
    _truckFocus.dispose();
    _driverFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = widget.state.startDate == null
        ? 'Date Range'
        : '${_fmtDate(widget.state.startDate!)} → ${_fmtDate(widget.state.endDate!)}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.viewModel.clearFilters();
                      widget.viewModel.applyFilters();
                      _truckController.clear();
                      _driverController.clear();
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: widget.state.type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'fuel', child: Text('Fuel')),
                  DropdownMenuItem(value: 'repair', child: Text('Repair')),
                  DropdownMenuItem(value: 'toll', child: Text('Toll')),
                  DropdownMenuItem(value: 'parking', child: Text('Parking')),
                  DropdownMenuItem(value: 'penalty', child: Text('Penalty')),
                  DropdownMenuItem(value: 'office_misc', child: Text('Office Misc')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  widget.viewModel.updateType(value);
                },
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 1),
                    initialDateRange: widget.state.startDate != null &&
                            widget.state.endDate != null
                        ? DateTimeRange(
                            start: widget.state.startDate!,
                            end: widget.state.endDate!,
                          )
                        : null,
                  );
                  widget.viewModel
                      .updateDateRange(picked?.start, picked?.end);
                },
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text(dateLabel),
              ),
              const SizedBox(height: 12),
              _FilterAutocomplete<TruckEntity>(
                controller: _truckController,
                focusNode: _truckFocus,
                label: 'Truck plate',
                options: _dedupeTrucks(widget.trucks),
                displayString: (truck) => truck.plateNo,
                onSelected: (truck) {
                  widget.viewModel.updateTruck(truck.id, truck.plateNo);
                },
                onQueryChanged: widget.viewModel.updatePlateNo,
                onCleared: () => widget.viewModel.updateTruck(null, null),
                enabled: !widget.loadingLookups,
              ),
              const SizedBox(height: 12),
              _FilterAutocomplete<DriverEntity>(
                controller: _driverController,
                focusNode: _driverFocus,
                label: 'Driver',
                options: _dedupeDrivers(widget.drivers),
                displayString: (driver) => driver.name,
                onSelected: (driver) {
                  widget.viewModel.updateDriver(driver.id, driver.name);
                },
                onQueryChanged: widget.viewModel.updateDriverName,
                onCleared: () => widget.viewModel.updateDriver(null, null),
                enabled: !widget.loadingLookups,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await widget.viewModel.applyFilters();
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _driverNameFromId(String? driverId, List<DriverEntity> drivers) {
  if (driverId == null || driverId.isEmpty) return null;
  final driver = drivers.firstWhere(
    (item) => item.id == driverId,
    orElse: () => const DriverEntity(
      id: '',
      name: '',
      driverType: '',
      status: '',
    ),
  );
  if (driver.id.isEmpty) return null;
  return driver.name;
}

String? _truckPlateFromId(String? truckId, List<TruckEntity> trucks) {
  if (truckId == null || truckId.isEmpty) return null;
  final truck = trucks.firstWhere(
    (item) => item.id == truckId,
    orElse: () => const TruckEntity(
      id: '',
      plateNo: '',
      truckType: '',
      status: '',
    ),
  );
  if (truck.id.isEmpty) return null;
  return truck.plateNo;
}

class _FilterAutocomplete<T extends Object> extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final List<T> options;
  final String Function(T) displayString;
  final ValueChanged<T> onSelected;
  final ValueChanged<String?> onQueryChanged;
  final VoidCallback onCleared;
  final bool enabled;

  const _FilterAutocomplete({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.options,
    required this.displayString,
    required this.onSelected,
    required this.onQueryChanged,
    required this.onCleared,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<T>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: displayString,
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return Iterable<T>.empty();
        return options.where(
          (item) => displayString(item).toLowerCase().contains(query),
        );
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: textController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      textController.clear();
                      onQueryChanged('');
                      onCleared();
                    },
                  ),
          ),
          onChanged: (value) {
            onQueryChanged(value);
            if (value.trim().isEmpty) {
              onCleared();
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: SizedBox(
              width: 320,
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: options
                    .map(
                      (item) => ListTile(
                        title: Text(displayString(item)),
                        onTap: () => onSelectedOption(item),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

List<TruckEntity> _dedupeTrucks(List<TruckEntity> items) {
  final seen = <String>{};
  final result = <TruckEntity>[];
  for (final truck in items) {
    if (truck.id.isEmpty || seen.contains(truck.id)) continue;
    seen.add(truck.id);
    result.add(truck);
  }
  return result;
}

List<DriverEntity> _dedupeDrivers(List<DriverEntity> items) {
  final seen = <String>{};
  final result = <DriverEntity>[];
  for (final driver in items) {
    if (driver.id.isEmpty || seen.contains(driver.id)) continue;
    seen.add(driver.id);
    result.add(driver);
  }
  return result;
}

class _SummaryRow extends StatelessWidget {
  final List<ExpenseEntity> expenses;
  final bool compact;

  const _SummaryRow({
    required this.expenses,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final fuel = expenses
        .where((e) => e.type == 'fuel')
        .fold<double>(0, (sum, e) => sum + e.amount);
    final repairs = expenses
        .where((e) => e.type == 'repair')
        .fold<double>(0, (sum, e) => sum + e.amount);
    final other = total - fuel - repairs;

    final cards = [
      _SummaryCard(
        label: 'Total',
        value: total,
        icon: Icons.account_balance_wallet_rounded,
        gradient: const [Color(0xFF0F172A), Color(0xFF1E3A8A)],
      ),
      _SummaryCard(
        label: 'Fuel',
        value: fuel,
        icon: Icons.local_gas_station_rounded,
        gradient: const [Color(0xFF064E3B), Color(0xFF0F766E)],
      ),
      _SummaryCard(
        label: 'Repair',
        value: repairs,
        icon: Icons.build_circle_rounded,
        gradient: const [Color(0xFF7C2D12), Color(0xFFB45309)],
      ),
      _SummaryCard(
        label: 'Other',
        value: other,
        icon: Icons.auto_graph_rounded,
        gradient: const [Color(0xFF312E81), Color(0xFF1D4ED8)],
      ),
    ];

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(width: 160, child: cards[index]);
            },
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: card,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final List<Color> gradient;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.roboto(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value.toStringAsFixed(2),
            style: GoogleFonts.roboto(
              textStyle: theme.textTheme.headlineSmall,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseLogSheet extends StatelessWidget {
  const _ExpenseLogSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Expense Logs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: ExpenseLogBuffer.clear,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ValueListenableBuilder<List<ExpenseLogEntry>>(
                valueListenable: ExpenseLogBuffer.logs,
                builder: (context, logs, _) {
                  if (logs.isEmpty) {
                    return const Text('No logs yet.');
                  }
                  final reversed = logs.reversed.toList();
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: reversed.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final entry = reversed[index];
                      final time =
                          '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
                          '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
                          '${entry.timestamp.second.toString().padLeft(2, '0')}';
                      return Text('[$time] ${entry.message}');
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTable extends StatelessWidget {
  final List<ExpenseEntity> expenses;
  final List<TruckEntity> trucks;
  final List<DriverEntity> drivers;
  final bool shrinkWrap;

  const _ExpenseTable({
    required this.expenses,
    required this.trucks,
    required this.drivers,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _ExpenseItemCard(
          expense: expenses[index],
          trucks: trucks,
          drivers: drivers,
          isCompact: false,
        );
      },
    );
  }
}

class _ExpenseCards extends StatelessWidget {
  final List<ExpenseEntity> expenses;
  final List<TruckEntity> trucks;
  final List<DriverEntity> drivers;
  final bool shrinkWrap;

  const _ExpenseCards({
    required this.expenses,
    required this.trucks,
    required this.drivers,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _ExpenseItemCard(
          expense: expenses[index],
          trucks: trucks,
          drivers: drivers,
          isCompact: true,
        );
      },
    );
  }
}

class _ExpenseItemCard extends StatelessWidget {
  final ExpenseEntity expense;
  final List<TruckEntity> trucks;
  final List<DriverEntity> drivers;
  final bool isCompact;

  const _ExpenseItemCard({
    required this.expense,
    required this.trucks,
    required this.drivers,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _typeColor(expense.type, theme);
    final driver = _driverLabel(expense.driverId, expense.notes, drivers);
    final truck = _truckLabel(expense.truckId, trucks);
    final amountStyle = GoogleFonts.roboto(
      textStyle: theme.textTheme.titleLarge,
      fontWeight: FontWeight.w700,
    );
    final captionStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.of(context).pushNamed(
            AppRoutes.expenseDetail,
            arguments: expense,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: isCompact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TypePill(type: expense.type, color: typeColor),
                              const SizedBox(height: 8),
                              Text(expense.amount.toStringAsFixed(2),
                                  style: amountStyle),
                              const SizedBox(height: 4),
                              Text(expense.expenseDate, style: captionStyle),
                              const SizedBox(height: 8),
                              Text('$truck • $driver'),
                              if (expense.notes != null &&
                                  expense.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    expense.notes!,
                                    style: captionStyle,
                                  ),
                                ),
                            ],
                          )
                        : Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _TypePill(
                                      type: expense.type, color: typeColor),
                                  const SizedBox(height: 8),
                                  Text(expense.expenseDate, style: captionStyle),
                                ],
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('$truck • $driver'),
                                    if (expense.notes != null &&
                                        expense.notes!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          expense.notes!,
                                          style: captionStyle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                expense.amount.toStringAsFixed(2),
                                style: amountStyle,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String type;
  final Color color;

  const _TypePill({
    required this.type,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForType(type), size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            type.toUpperCase(),
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'fuel':
      return Icons.local_gas_station_rounded;
    case 'repair':
    case 'maintenance':
      return Icons.build_rounded;
    case 'toll':
      return Icons.toll_rounded;
    case 'parking':
      return Icons.local_parking_rounded;
    case 'penalty':
      return Icons.warning_rounded;
    case 'office_misc':
      return Icons.business_center_rounded;
    default:
      return Icons.receipt_long_rounded;
  }
}

Color _typeColor(String type, ThemeData theme) {
  switch (type) {
    case 'fuel':
      return const Color(0xFF0F766E);
    case 'repair':
    case 'maintenance':
      return const Color(0xFFB45309);
    case 'toll':
      return const Color(0xFF2563EB);
    case 'parking':
      return const Color(0xFF7C3AED);
    case 'penalty':
      return const Color(0xFFDC2626);
    case 'office_misc':
      return const Color(0xFF1D4ED8);
    default:
      return theme.colorScheme.primary;
  }
}

String _truckLabel(String? truckId, List<TruckEntity> trucks) {
  if (truckId == null || truckId.isEmpty) return 'No truck';
  final truck = trucks.firstWhere(
    (item) => item.id == truckId,
    orElse: () => const TruckEntity(id: '', plateNo: '-', status: ''),
  );
  return truck.id.isEmpty ? 'Truck' : truck.plateNo;
}

String _driverLabel(
  String? driverId,
  String? notes,
  List<DriverEntity> drivers,
) {
  if (driverId != null && driverId.isNotEmpty) {
    final driver = drivers.firstWhere(
      (item) => item.id == driverId,
      orElse: () => const DriverEntity(
        id: '',
        name: 'Driver',
        driverType: '',
        status: '',
      ),
    );
    if (driver.id.isNotEmpty) return driver.name;
  }

  if (notes != null && notes.isNotEmpty) {
    final lower = notes.toLowerCase();
    final marker = 'driver:';
    final index = lower.indexOf(marker);
    if (index != -1) {
      final after = notes.substring(index + marker.length).trim();
      final end = after.indexOf('|');
      final name = (end == -1 ? after : after.substring(0, end)).trim();
      if (name.isNotEmpty) return name;
    }
  }

  return 'No driver';
}

String _rangeLabel(ExpenseListState state) {
  if (state.startDate == null && state.endDate == null) {
    return 'All time';
  }
  final start = state.startDate ?? state.endDate;
  final end = state.endDate ?? state.startDate;
  if (start == null || end == null) return 'All time';
  return '${start.day}/${start.month}/${start.year} → ${end.day}/${end.month}/${end.year}';
}

String _fmtDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String _monthLabel(ExpenseListState state) {
  if (state.startDate == null) return 'All months';
  return DateFormat('MMM yyyy').format(state.startDate!);
}

Future<void> _pickMonth(
  BuildContext context,
  ExpenseListViewModel viewModel,
  ExpenseListState state,
) async {
  final now = DateTime.now();
  final initial = state.startDate ?? now;
  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(now.year - 5),
    lastDate: DateTime(now.year + 1),
  );
  if (picked == null) return;
  final first = DateTime(picked.year, picked.month, 1);
  final last = DateTime(picked.year, picked.month + 1, 0);
  viewModel.updateDateRange(first, last);
  await viewModel.applyFilters();
}

int _activeFilterCount(ExpenseListState state) {
  var count = 0;
  if (state.type != 'all') count++;
  if (state.startDate != null || state.endDate != null) count++;
  if (state.truckId != null && state.truckId!.isNotEmpty) count++;
  if (state.driverId != null && state.driverId!.isNotEmpty) count++;
  return count;
}

List<ExpenseEntity> _applySearch(
  List<ExpenseEntity> expenses,
  String query,
  List<TruckEntity> trucks,
  List<DriverEntity> drivers,
) {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return expenses;
  return expenses.where((e) {
    final truck = _truckLabel(e.truckId, trucks).toLowerCase();
    final driver = _driverLabel(e.driverId, e.notes, drivers).toLowerCase();
    return e.notes?.toLowerCase().contains(trimmed) == true ||
        e.type.toLowerCase().contains(trimmed) ||
        e.expenseDate.toLowerCase().contains(trimmed) ||
        e.amount.toString().contains(trimmed) ||
        (e.tripId ?? '').toLowerCase().contains(trimmed) ||
        truck.contains(trimmed) ||
        driver.contains(trimmed);
  }).toList();
}
