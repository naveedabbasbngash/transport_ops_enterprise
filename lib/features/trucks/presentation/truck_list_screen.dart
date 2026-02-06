import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'truck_view_model.dart';

class TruckListScreen extends ConsumerWidget {
  const TruckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(truckViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final isReadOnly = authState.user?.isOwnerReadOnly ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trucks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.isLoading
                ? null
                : () => ref.read(truckViewModelProvider.notifier).loadTrucks(),
          ),
        ],
      ),
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openCreateTruck(context, ref),
              label: const Text('Add Truck'),
              icon: const Icon(Icons.add_rounded),
            ),
      body: Column(
        children: [
          _Filters(
            search: state.search,
            status: state.status,
            onSearchChanged: (value) =>
                ref.read(truckViewModelProvider.notifier).updateSearch(value),
            onStatusChanged: (value) =>
                ref.read(truckViewModelProvider.notifier).updateStatus(value),
            onApply: () =>
                ref.read(truckViewModelProvider.notifier).applyFilters(),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                state.error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.trucks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final truck = state.trucks[index];
                      return Card(
                        child: ListTile(
                          title: Text(truck.plateNo),
                          subtitle: Text(
                            [
                              if (truck.truckType != null &&
                                  truck.truckType!.isNotEmpty)
                                truck.truckType!,
                              truck.status,
                            ].join(' • '),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateTruck(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateTruckSheet(
        onSubmit: (payload) async {
          await ref.read(truckViewModelProvider.notifier).createTruck(
                plateNo: payload.plateNo,
                truckType: payload.truckType,
                color: payload.color,
                model: payload.model,
                makeYear: payload.makeYear,
                registrationNumber: payload.registrationNumber,
                ownership: payload.ownership,
                vendorId: payload.vendorId,
                notes: payload.notes,
              );
        },
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final String search;
  final String status;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onApply;

  const _Filters({
    required this.search,
    required this.status,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search plate',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (value) {
                if (value == null) return;
                onStatusChanged(value);
              },
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onApply,
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _CreateTruckPayload {
  final String plateNo;
  final String? truckType;
  final String? color;
  final String? model;
  final String? makeYear;
  final String? registrationNumber;
  final String? ownership;
  final String? vendorId;
  final String? notes;

  const _CreateTruckPayload({
    required this.plateNo,
    this.truckType,
    this.color,
    this.model,
    this.makeYear,
    this.registrationNumber,
    this.ownership,
    this.vendorId,
    this.notes,
  });
}

class _CreateTruckSheet extends StatefulWidget {
  final Future<void> Function(_CreateTruckPayload payload) onSubmit;

  const _CreateTruckSheet({
    required this.onSubmit,
  });

  @override
  State<_CreateTruckSheet> createState() => _CreateTruckSheetState();
}

class _CreateTruckSheetState extends State<_CreateTruckSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _typeController = TextEditingController();
  final _colorController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _regController = TextEditingController();
  final _vendorController = TextEditingController();
  final _notesController = TextEditingController();
  String _ownership = 'company';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _plateController.dispose();
    _typeController.dispose();
    _colorController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _regController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New Truck',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: 'Plate number'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Required'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Truck type'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _ownership,
                decoration: const InputDecoration(labelText: 'Ownership'),
                items: const [
                  DropdownMenuItem(value: 'company', child: Text('Company')),
                  DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _ownership = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vendorController,
                decoration: const InputDecoration(labelText: 'Vendor ID (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Make year'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _regController,
                decoration:
                    const InputDecoration(labelText: 'Registration number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isSubmitting = true);
                        await widget.onSubmit(
                          _CreateTruckPayload(
                            plateNo: _plateController.text.trim(),
                            truckType: _typeController.text.trim(),
                            color: _colorController.text.trim(),
                            model: _modelController.text.trim(),
                            makeYear: _yearController.text.trim(),
                            registrationNumber: _regController.text.trim(),
                            ownership: _ownership,
                            vendorId: _vendorController.text.trim(),
                            notes: _notesController.text.trim(),
                          ),
                        );
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Truck'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
