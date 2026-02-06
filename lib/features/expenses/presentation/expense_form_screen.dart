import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../drivers/domain/entities/driver_entity.dart';
import '../../trucks/domain/entities/truck_entity.dart';
import '../../../shared/providers/driver_repository_provider.dart';
import '../../../shared/providers/truck_repository_provider.dart';
import '../domain/entities/expense_entity.dart';
import '../../../core/logging/expense_log_buffer.dart';
import 'expense_view_model.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final ExpenseEntity? expense;

  const ExpenseFormScreen({super.key, this.expense});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _tripIdController = TextEditingController();
  final _truckController = TextEditingController();
  final _driverController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'fuel';
  bool _loadingLookups = true;
  List<TruckEntity> _trucks = const [];
  List<DriverEntity> _drivers = const [];
  TruckEntity? _selectedTruck;
  DriverEntity? _selectedDriver;
  bool _isEdit = false;

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _tripIdController.dispose();
    _truckController.dispose();
    _driverController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isEdit = widget.expense != null;
    _amountController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    if (widget.expense != null) {
      final expense = widget.expense!;
      _dateController.text = expense.expenseDate;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _tripIdController.text = expense.tripId ?? '';
      _vendorController.text = expense.vendorId ?? '';
      _notesController.text = expense.notes ?? '';
      _type = expense.type.isNotEmpty ? expense.type : 'fuel';
    }
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final driverRepo = ref.read(driverRepositoryProvider);
      final truckRepo = ref.read(truckRepositoryProvider);
      final results = await Future.wait([
        driverRepo.getDrivers(status: 'active'),
        truckRepo.getTrucks(status: 'active'),
      ]);
      if (!mounted) return;
      setState(() {
        _drivers = results[0] as List<DriverEntity>;
        _trucks = results[1] as List<TruckEntity>;
        if (widget.expense != null) {
          final expense = widget.expense!;
          _selectedTruck = _trucks.firstWhere(
            (truck) => truck.id == expense.truckId,
            orElse: () => const TruckEntity(
              id: '',
              plateNo: '',
              status: '',
            ),
          );
          if (_selectedTruck?.id == '') _selectedTruck = null;
          _selectedDriver = _drivers.firstWhere(
            (driver) => driver.id == expense.driverId,
            orElse: () => const DriverEntity(
              id: '',
              name: '',
              driverType: '',
              status: '',
            ),
          );
          if (_selectedDriver?.id == '') _selectedDriver = null;
          if (_selectedTruck != null) {
            _truckController.text = _selectedTruck!.plateNo;
          }
          if (_selectedDriver != null) {
            _driverController.text = _selectedDriver!.name;
          }
        }
        _loadingLookups = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLookups = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseViewModelProvider);
    final theme = Theme.of(context);
    final inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      isDense: true,
    );
    final headerStyle = GoogleFonts.roboto(
      textStyle: theme.textTheme.headlineSmall,
      fontWeight: FontWeight.w700,
    );
    final sectionStyle = GoogleFonts.roboto(
      textStyle: theme.textTheme.titleMedium,
      fontWeight: FontWeight.w600,
    );

    final detailsSection = _SectionCard(
      title: 'Expense details',
      titleStyle: sectionStyle,
      child: Column(
        children: [
          TextFormField(
            controller: _dateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Expense date',
              prefixIcon: Icon(Icons.calendar_today_rounded),
            ),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 1),
                initialDate: DateTime.tryParse(_dateController.text) ?? now,
              );
              if (picked == null) return;
              final formatted =
                  '${picked.year.toString().padLeft(4, '0')}-'
                  '${picked.month.toString().padLeft(2, '0')}-'
                  '${picked.day.toString().padLeft(2, '0')}';
              _dateController.text = formatted;
            },
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Type',
              prefixIcon: Icon(Icons.tune_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'fuel', child: Text('Fuel')),
              DropdownMenuItem(value: 'repair', child: Text('Repair')),
              DropdownMenuItem(value: 'toll', child: Text('Toll')),
              DropdownMenuItem(value: 'penalty', child: Text('Penalty')),
              DropdownMenuItem(value: 'parking', child: Text('Parking')),
              DropdownMenuItem(value: 'office_misc', child: Text('Office Misc')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _type = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.payments_rounded),
            ),
            keyboardType: TextInputType.number,
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );

    final linkSection = _SectionCard(
      title: 'Linking',
      titleStyle: sectionStyle,
      child: Column(
        children: [
          _loadingLookups
              ? const LinearProgressIndicator()
              : _TruckAutocomplete(
                  controller: _truckController,
                  trucks: _trucks,
                  selected: _selectedTruck,
                  enabled: !_isEdit,
                  onSelected: (truck) {
                    setState(() => _selectedTruck = truck);
                  },
                ),
          const SizedBox(height: 12),
          _loadingLookups
              ? const SizedBox.shrink()
              : _DriverAutocomplete(
                  controller: _driverController,
                  drivers: _drivers,
                  selected: _selectedDriver,
                  enabled: !_isEdit,
                  onSelected: (driver) {
                    setState(() => _selectedDriver = driver);
                  },
                ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tripIdController,
            decoration: const InputDecoration(
              labelText: 'Trip ID (optional)',
              prefixIcon: Icon(Icons.route_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _vendorController,
            decoration: const InputDecoration(
              labelText: 'Vendor ID (optional)',
              prefixIcon: Icon(Icons.store_mall_directory_rounded),
            ),
          ),
        ],
      ),
    );

    final notesSection = _SectionCard(
      title: 'Notes',
      titleStyle: sectionStyle,
      child: TextFormField(
        controller: _notesController,
        decoration: const InputDecoration(
          labelText: 'Add context',
          prefixIcon: Icon(Icons.edit_note_rounded),
        ),
        maxLines: 2,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Expense' : 'Add Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => _openExpenseLogs(context),
          ),
        ],
      ),
      body: Theme(
        data: theme.copyWith(inputDecorationTheme: inputTheme),
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _FormHeader(
                    isEdit: _isEdit,
                    headerStyle: headerStyle,
                    amount: _amountController.text.trim(),
                    type: _type,
                  ),
                  const SizedBox(height: 16),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: detailsSection),
                        const SizedBox(width: 16),
                        Expanded(child: linkSection),
                      ],
                    )
                  else ...[
                    detailsSection,
                    const SizedBox(height: 16),
                    linkSection,
                  ],
                  const SizedBox(height: 16),
                  notesSection,
                  const SizedBox(height: 16),
                  if (state.error != null)
                    Text(
                      state.error!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: state.isSubmitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (!_isEdit) {
                              if (_truckController.text.trim().isNotEmpty &&
                                  _selectedTruck == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Select a truck from the list.'),
                                  ),
                                );
                                return;
                              }
                              if (_driverController.text.trim().isNotEmpty &&
                                  _selectedDriver == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Select a driver from the list.'),
                                  ),
                                );
                                return;
                              }
                            }

                            if (_isEdit) {
                              final uiPayload = <String, dynamic>{
                                'id': widget.expense!.id,
                                'expense_date': _dateController.text.trim(),
                                'type': _type,
                                'amount': _amountController.text.trim(),
                                'notes': _notesController.text.trim(),
                              };
                              debugPrint('EXPENSE UI update payload: $uiPayload');
                              await ref
                                  .read(expenseViewModelProvider.notifier)
                                  .updateExpense(
                                    id: widget.expense!.id,
                                    expenseDate: _dateController.text.trim(),
                                    type: _type,
                                    amount: _amountController.text.trim(),
                                    notes: _notesController.text.trim(),
                                  );
                            } else {
                              final rawNotes = _notesController.text.trim();
                              final driverName = _selectedDriver?.name ?? '';
                              final notesWithDriver = driverName.isEmpty
                                  ? rawNotes
                                  : (rawNotes.toLowerCase().contains(
                                          driverName.toLowerCase(),
                                        )
                                      ? rawNotes
                                      : (rawNotes.isEmpty
                                          ? 'Driver: $driverName'
                                          : '$rawNotes | Driver: $driverName'));

                              final uiPayload = <String, dynamic>{
                                'expense_date': _dateController.text.trim(),
                                'type': _type,
                                'amount': _amountController.text.trim(),
                                'trip_id': _tripIdController.text.trim(),
                                'truck_id': _selectedTruck?.id ?? '',
                                'truck_plate': _selectedTruck?.plateNo ?? '',
                                'driver_id': _selectedDriver?.id ?? '',
                                'driver_name': _selectedDriver?.name ?? '',
                                'vendor_id': _vendorController.text.trim(),
                                'notes': notesWithDriver,
                              };
                              debugPrint('EXPENSE UI create payload: $uiPayload');
                              await ref
                                  .read(expenseViewModelProvider.notifier)
                                  .createExpense(
                                    expenseDate: _dateController.text.trim(),
                                    type: _type,
                                    amount: _amountController.text.trim(),
                                    tripId: _tripIdController.text.trim(),
                                    truckId: _selectedTruck?.id ?? '',
                                    driverId: _selectedDriver?.id ?? '',
                                    vendorId: _vendorController.text.trim(),
                                    notes: notesWithDriver,
                                  );
                            }
                            if (!mounted) return;
                            if (ref.read(expenseViewModelProvider).success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isEdit
                                      ? 'Expense updated'
                                      : 'Expense saved'),
                                ),
                              );
                              Navigator.of(context).pop(true);
                            }
                          },
                    icon: state.isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_rounded),
                    label:
                        Text(_isEdit ? 'Update Expense' : 'Save Expense'),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
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

class _FormHeader extends StatelessWidget {
  final bool isEdit;
  final TextStyle headerStyle;
  final String amount;
  final String type;

  const _FormHeader({
    required this.isEdit,
    required this.headerStyle,
    required this.amount,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleStyle = GoogleFonts.roboto(
      textStyle: theme.textTheme.bodyMedium,
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit expense' : 'New expense',
                    style: headerStyle.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  'Track fuel, repairs, tolls, and penalties in one flow.',
                  style: subtitleStyle.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(
                  amount.isEmpty ? '--' : amount,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type.toUpperCase(),
                  style: GoogleFonts.roboto(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final TextStyle titleStyle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.titleStyle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: titleStyle),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _TruckAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final List<TruckEntity> trucks;
  final TruckEntity? selected;
  final ValueChanged<TruckEntity> onSelected;
  final bool enabled;

  const _TruckAutocomplete({
    required this.controller,
    required this.trucks,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<TruckEntity>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return const Iterable<TruckEntity>.empty();
        return trucks.where(
          (truck) => truck.plateNo.toLowerCase().contains(query),
        );
      },
      displayStringForOption: (truck) => truck.plateNo,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        textController.text = controller.text;
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Truck plate (type to search)',
            prefixIcon: Icon(Icons.local_shipping_rounded),
          ),
          enabled: enabled,
          onChanged: (value) => controller.text = value,
        );
      },
      onSelected: (truck) {
        controller.text = truck.plateNo;
        onSelected(truck);
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: options
                    .map(
                      (truck) => ListTile(
                        title: Text(truck.plateNo),
                        subtitle: Text(truck.truckType ?? 'Truck'),
                        onTap: () => onSelectedOption(truck),
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

class _DriverAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final List<DriverEntity> drivers;
  final DriverEntity? selected;
  final ValueChanged<DriverEntity> onSelected;
  final bool enabled;

  const _DriverAutocomplete({
    required this.controller,
    required this.drivers,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<DriverEntity>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return const Iterable<DriverEntity>.empty();
        return drivers.where(
          (driver) => driver.name.toLowerCase().contains(query),
        );
      },
      displayStringForOption: (driver) => driver.name,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        textController.text = controller.text;
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Driver name (type to search)',
            prefixIcon: Icon(Icons.person_rounded),
          ),
          enabled: enabled,
          onChanged: (value) => controller.text = value,
        );
      },
      onSelected: (driver) {
        controller.text = driver.name;
        onSelected(driver);
      },
      optionsViewBuilder: (context, onSelectedOption, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: options
                    .map(
                      (driver) => ListTile(
                        title: Text(driver.name),
                        subtitle: Text(driver.phone ?? driver.driverType),
                        onTap: () => onSelectedOption(driver),
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
