import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'driver_view_model.dart';

class DriverListScreen extends ConsumerWidget {
  const DriverListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(driverViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final isReadOnly = authState.user?.isOwnerReadOnly ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.isLoading
                ? null
                : () => ref.read(driverViewModelProvider.notifier).loadDrivers(),
          ),
        ],
      ),
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openCreateDriver(context, ref),
              label: const Text('Add Driver'),
              icon: const Icon(Icons.add_rounded),
            ),
      body: Column(
        children: [
          _Filters(
            search: state.search,
            status: state.status,
            onSearchChanged: (value) =>
                ref.read(driverViewModelProvider.notifier).updateSearch(value),
            onStatusChanged: (value) =>
                ref.read(driverViewModelProvider.notifier).updateStatus(value),
            onApply: () =>
                ref.read(driverViewModelProvider.notifier).applyFilters(),
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
                    itemCount: state.drivers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final driver = state.drivers[index];
                      return Card(
                        child: ListTile(
                          title: Text(driver.name),
                          subtitle: Text(
                            [
                              if (driver.phone != null &&
                                  driver.phone!.isNotEmpty)
                                driver.phone!,
                              driver.driverType,
                              driver.status,
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

  Future<void> _openCreateDriver(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateDriverSheet(
        onSubmit: (payload) async {
          await ref.read(driverViewModelProvider.notifier).createDriver(
                name: payload.name,
                driverType: payload.driverType,
                phone: payload.phone,
                residentId: payload.residentId,
                vendorId: payload.vendorId,
                licenseNo: payload.licenseNo,
                licenseExpiry: payload.licenseExpiry,
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
                labelText: 'Search driver',
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
                DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
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

class _CreateDriverPayload {
  final String name;
  final String driverType;
  final String? phone;
  final String? residentId;
  final String? vendorId;
  final String? licenseNo;
  final String? licenseExpiry;
  final String? notes;

  const _CreateDriverPayload({
    required this.name,
    required this.driverType,
    this.phone,
    this.residentId,
    this.vendorId,
    this.licenseNo,
    this.licenseExpiry,
    this.notes,
  });
}

class _CreateDriverSheet extends StatefulWidget {
  final Future<void> Function(_CreateDriverPayload payload) onSubmit;

  const _CreateDriverSheet({
    required this.onSubmit,
  });

  @override
  State<_CreateDriverSheet> createState() => _CreateDriverSheetState();
}

class _CreateDriverSheetState extends State<_CreateDriverSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _residentIdController = TextEditingController();
  final _vendorIdController = TextEditingController();
  final _licenseNoController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  final _notesController = TextEditingController();
  String _driverType = 'company';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _residentIdController.dispose();
    _vendorIdController.dispose();
    _licenseNoController.dispose();
    _licenseExpiryController.dispose();
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
                'New Driver',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Driver name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Required'
                        : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _driverType,
                decoration: const InputDecoration(labelText: 'Driver type'),
                items: const [
                  DropdownMenuItem(value: 'company', child: Text('Company')),
                  DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _driverType = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _residentIdController,
                decoration: const InputDecoration(labelText: 'Resident ID'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _licenseNoController,
                decoration: const InputDecoration(labelText: 'License No'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _licenseExpiryController,
                decoration:
                    const InputDecoration(labelText: 'License Expiry (YYYY-MM-DD)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vendorIdController,
                decoration: const InputDecoration(labelText: 'Vendor ID (optional)'),
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
                          _CreateDriverPayload(
                            name: _nameController.text.trim(),
                            driverType: _driverType,
                            phone: _phoneController.text.trim(),
                            residentId: _residentIdController.text.trim(),
                            vendorId: _vendorIdController.text.trim(),
                            licenseNo: _licenseNoController.text.trim(),
                            licenseExpiry: _licenseExpiryController.text.trim(),
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
                    : const Text('Save Driver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
