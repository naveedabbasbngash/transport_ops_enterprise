import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/providers/driver_repository_provider.dart';
import '../../../shared/providers/truck_repository_provider.dart';
import '../../drivers/domain/entities/driver_entity.dart';
import '../../trucks/domain/entities/truck_entity.dart';
import '../domain/entities/expense_entity.dart';
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
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();

  String _type = 'fuel';
  bool _isEdit = false;
  bool _loadingLookups = true;

  List<TruckEntity> _trucks = const [];
  List<DriverEntity> _drivers = const [];
  TruckEntity? _selectedTruck;
  DriverEntity? _selectedDriver;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.expense != null;
    if (_isEdit) {
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

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _tripIdController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
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
        if (_isEdit) {
          final expense = widget.expense!;
          _selectedTruck = _trucks
              .where((t) => t.id == expense.truckId)
              .firstOrNull;
          _selectedDriver = _drivers
              .where((d) => d.id == expense.driverId)
              .firstOrNull;
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

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: _isEdit ? 'Edit Expense' : 'New Expense'),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: AppSpacing.page,
                  children: [
                    _Hero(type: _type, isEdit: _isEdit),
                    if (_loadingLookups) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _Panel(
                      title: 'Expense Details',
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
                                initialDate:
                                    DateTime.tryParse(_dateController.text) ??
                                    now,
                              );
                              if (picked == null) return;
                              _dateController.text =
                                  '${picked.year.toString().padLeft(4, '0')}-'
                                  '${picked.month.toString().padLeft(2, '0')}-'
                                  '${picked.day.toString().padLeft(2, '0')}';
                            },
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _type,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              prefixIcon: Icon(Icons.tune_rounded),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'fuel',
                                child: Text('Fuel'),
                              ),
                              DropdownMenuItem(
                                value: 'repair',
                                child: Text('Repair'),
                              ),
                              DropdownMenuItem(
                                value: 'toll',
                                child: Text('Toll'),
                              ),
                              DropdownMenuItem(
                                value: 'penalty',
                                child: Text('Penalty'),
                              ),
                              DropdownMenuItem(
                                value: 'parking',
                                child: Text('Parking'),
                              ),
                              DropdownMenuItem(
                                value: 'office_misc',
                                child: Text('Office Misc'),
                              ),
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Panel(
                      title: 'Linking',
                      child: Column(
                        children: [
                          DropdownButtonFormField<TruckEntity>(
                            initialValue: _selectedTruck,
                            decoration: const InputDecoration(
                              labelText: 'Truck (optional)',
                              prefixIcon: Icon(Icons.local_shipping_rounded),
                            ),
                            items: _trucks
                                .map(
                                  (truck) => DropdownMenuItem(
                                    value: truck,
                                    child: Text(truck.plateNo),
                                  ),
                                )
                                .toList(),
                            onChanged: _isEdit
                                ? null
                                : (value) {
                                    setState(() => _selectedTruck = value);
                                  },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<DriverEntity>(
                            initialValue: _selectedDriver,
                            decoration: const InputDecoration(
                              labelText: 'Driver (optional)',
                              prefixIcon: Icon(Icons.person_rounded),
                            ),
                            items: _drivers
                                .map(
                                  (driver) => DropdownMenuItem(
                                    value: driver,
                                    child: Text(driver.name),
                                  ),
                                )
                                .toList(),
                            onChanged: _isEdit
                                ? null
                                : (value) {
                                    setState(() => _selectedDriver = value);
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
                              prefixIcon: Icon(Icons.storefront_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Panel(
                      title: 'Notes',
                      child: TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Add context',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (state.error != null)
                      _ErrorBanner(message: state.error!),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: state.isSubmitting ? null : _submit,
                      icon: state.isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isEdit ? 'Update Expense' : 'Save Expense'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = ref.read(expenseViewModelProvider.notifier);
    if (_isEdit) {
      await vm.updateExpense(
        id: widget.expense!.id,
        expenseDate: _dateController.text.trim(),
        type: _type,
        amount: _amountController.text.trim(),
        notes: _notesController.text.trim(),
      );
    } else {
      await vm.createExpense(
        expenseDate: _dateController.text.trim(),
        type: _type,
        amount: _amountController.text.trim(),
        tripId: _tripIdController.text.trim(),
        truckId: _selectedTruck?.id ?? '',
        driverId: _selectedDriver?.id ?? '',
        vendorId: _vendorController.text.trim(),
        notes: _notesController.text.trim(),
      );
    }

    if (!mounted) return;
    if (ref.read(expenseViewModelProvider).success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Expense updated' : 'Expense saved')),
      );
      Navigator.of(context).pop(true);
    }
  }
}

class _TopBar extends StatelessWidget {
  final String title;

  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: AppSpacing.topBar,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String type;
  final bool isEdit;

  const _Hero({required this.type, required this.isEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.page,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.heroDarkStart, AppColors.heroDarkEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          Text(
            isEdit ? 'Update Expense' : 'Create Expense',
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          _Pill(text: type.toUpperCase()),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;

  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.panel,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTypography.section,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.dangerDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
