import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../shared/providers/location_repository_provider.dart';
import '../../clients/domain/entities/client_entity.dart';
import '../../trips/domain/entities/location_entity.dart';
import '../domain/entities/order_entity.dart';
import 'orders_view_model.dart';

class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({super.key, this.order});

  final OrderEntity? order;

  bool get isEdit => order != null;

  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderNoController = TextEditingController();
  final _orderDateController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _revenueController = TextEditingController();
  final _vendorCostController = TextEditingController();
  final _otherCostController = TextEditingController();
  final _currencyController = TextEditingController();
  final _financialNotesController = TextEditingController();
  final _notesController = TextEditingController();
  final _clientController = TextEditingController();

  List<ClientEntity> _clients = const [];
  List<LocationEntity> _locations = const [];
  ClientEntity? _selectedClient;
  bool _loading = true;
  String _status = 'draft';

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    if (order != null) {
      _orderNoController.text = order.orderNo ?? '';
      _orderDateController.text = order.orderDate ?? '';
      _fromController.text = order.fromLocation ?? '';
      _toController.text = order.toLocation ?? '';
      _revenueController.text = order.revenueExpected.toStringAsFixed(2);
      _vendorCostController.text = order.vendorCost.toStringAsFixed(2);
      _otherCostController.text = order.companyOtherCost.toStringAsFixed(2);
      _currencyController.text = order.currency;
      _financialNotesController.text = order.financialNotes ?? '';
      _notesController.text = order.notes ?? '';
      _clientController.text = order.clientName ?? '';
      _status = order.status;
    } else {
      final now = DateTime.now();
      _orderDateController.text =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _revenueController.text = '0';
      _vendorCostController.text = '0';
      _otherCostController.text = '0';
      _currencyController.text = 'SAR';
    }
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final vm = ref.read(ordersViewModelProvider.notifier);
      final locationRepo = ref.read(locationRepositoryProvider);
      final results = await Future.wait<dynamic>([
        vm.getClients(status: 'active'),
        locationRepo.getLocations(status: 'active', limit: 500),
      ]);
      final clients = results[0] as List<ClientEntity>;
      final locations = results[1] as List<LocationEntity>;
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _locations = _uniqueLocations(locations);
        if (widget.order?.clientId != null) {
          _selectedClient = _findClientById(widget.order!.clientId!);
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _orderNoController.dispose();
    _orderDateController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _revenueController.dispose();
    _vendorCostController.dispose();
    _otherCostController.dispose();
    _currencyController.dispose();
    _financialNotesController.dispose();
    _notesController.dispose();
    _clientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(ordersViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: AppSpacing.topBar,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Text(
                    widget.isEdit ? 'Edit Order' : 'New Order',
                    style: const TextStyle(
                      fontSize: AppTypography.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: AppSpacing.page,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 920),
                          child: Form(
                            key: _formKey,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LookupAutocomplete<ClientEntity>(
                                    controller: _clientController,
                                    labelText: 'Client',
                                    hintText: 'Type client name',
                                    options: _clients,
                                    display: (item) => item.name,
                                    subtitle: (item) => item.status,
                                    onChanged: () => _selectedClient = null,
                                    onSelected: (item) {
                                      _selectedClient = item;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _orderNoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Order No (optional)',
                                      prefixIcon: Icon(Icons.numbers_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _LocationAutocomplete(
                                    controller: _fromController,
                                    labelText: 'From location',
                                    hintText: 'Type or select location',
                                    options: _locations,
                                    onChanged: () => setState(() {}),
                                    onSelected: (_) => setState(() {}),
                                  ),
                                  _LocationAddInline(
                                    text: _fromController.text,
                                    exists: _locationExists(
                                      _fromController.text,
                                    ),
                                    onAdd: () => _addLocationFromInput(
                                      _fromController,
                                      'From',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _LocationAutocomplete(
                                    controller: _toController,
                                    labelText: 'To location',
                                    hintText: 'Type or select location',
                                    options: _locations,
                                    onChanged: () => setState(() {}),
                                    onSelected: (_) => setState(() {}),
                                  ),
                                  _LocationAddInline(
                                    text: _toController.text,
                                    exists: _locationExists(_toController.text),
                                    onAdd: () => _addLocationFromInput(
                                      _toController,
                                      'To',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _orderDateController,
                                    readOnly: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Order Date',
                                      prefixIcon: Icon(
                                        Icons.calendar_today_rounded,
                                      ),
                                    ),
                                    onTap: () async {
                                      final now = DateTime.now();
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            DateTime.tryParse(
                                              _orderDateController.text,
                                            ) ??
                                            now,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        _orderDateController.text =
                                            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _revenueController,
                                    decoration: const InputDecoration(
                                      labelText: 'Revenue expected',
                                      prefixIcon: Icon(Icons.payments_outlined),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: (v) =>
                                        (v == null ||
                                            double.tryParse(v.trim()) == null)
                                        ? 'Enter valid amount'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _vendorCostController,
                                    decoration: const InputDecoration(
                                      labelText: 'Vendor cost',
                                      prefixIcon: Icon(
                                        Icons.storefront_outlined,
                                      ),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: (v) =>
                                        (v == null ||
                                            double.tryParse(v.trim()) == null)
                                        ? 'Enter valid amount'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _otherCostController,
                                    decoration: const InputDecoration(
                                      labelText: 'Other cost',
                                      prefixIcon: Icon(
                                        Icons.account_balance_wallet_outlined,
                                      ),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _currencyController,
                                    decoration: const InputDecoration(
                                      labelText: 'Currency',
                                      prefixIcon: Icon(
                                        Icons.currency_exchange_outlined,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _financialNotesController,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      labelText: 'Financial notes',
                                      prefixIcon: Icon(
                                        Icons.request_quote_outlined,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: _status,
                                    decoration: const InputDecoration(
                                      labelText: 'Status',
                                      prefixIcon: Icon(Icons.flag_rounded),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'draft',
                                        child: Text('Draft'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'confirmed',
                                        child: Text('Confirmed'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'in_progress',
                                        child: Text('In Progress'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'completed',
                                        child: Text('Completed'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'cancelled',
                                        child: Text('Cancelled'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => _status = value);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _notesController,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      labelText: 'Notes',
                                      prefixIcon: Icon(Icons.notes_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: vmState.isSubmitting
                                          ? null
                                          : _submit,
                                      icon: const Icon(Icons.save_rounded),
                                      label: Text(
                                        widget.isEdit
                                            ? 'Update Order'
                                            : 'Create Order',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  ClientEntity? _findClientById(String id) {
    for (final item in _clients) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Client is required.')));
      return;
    }

    final revenue = double.tryParse(_revenueController.text.trim()) ?? 0;
    final vendorCost = double.tryParse(_vendorCostController.text.trim()) ?? 0;
    final otherCost = double.tryParse(_otherCostController.text.trim()) ?? 0;

    final vm = ref.read(ordersViewModelProvider.notifier);
    final success = widget.isEdit
        ? await vm.updateOrder(
            widget.order!.id,
            clientId: _selectedClient!.id,
            fromLocation: _fromController.text.trim(),
            toLocation: _toController.text.trim(),
            revenueExpected: revenue,
            vendorCost: vendorCost,
            companyOtherCost: otherCost,
            currency: _currencyController.text.trim().isEmpty
                ? 'SAR'
                : _currencyController.text.trim(),
            financialNotes: _financialNotesController.text.trim(),
            orderNo: _orderNoController.text.trim(),
            status: _status,
            orderDate: _orderDateController.text.trim(),
            notes: _notesController.text.trim(),
          )
        : await vm.createOrder(
            clientId: _selectedClient!.id,
            fromLocation: _fromController.text.trim(),
            toLocation: _toController.text.trim(),
            revenueExpected: revenue,
            vendorCost: vendorCost,
            companyOtherCost: otherCost,
            currency: _currencyController.text.trim().isEmpty
                ? 'SAR'
                : _currencyController.text.trim(),
            financialNotes: _financialNotesController.text.trim(),
            orderNo: _orderNoController.text.trim(),
            status: _status,
            orderDate: _orderDateController.text.trim(),
            notes: _notesController.text.trim(),
          );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save order.')));
    }
  }

  bool _locationExists(String raw) {
    final needle = raw.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return _locations.any((item) => item.name.trim().toLowerCase() == needle);
  }

  Future<void> _addLocationFromInput(
    TextEditingController controller,
    String label,
  ) async {
    final name = controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Enter $label location first.')));
      return;
    }
    if (_locationExists(name)) return;

    try {
      final locationRepo = ref.read(locationRepositoryProvider);
      final created = await locationRepo.createLocation(name: name);
      if (!mounted) return;
      setState(() {
        _locations = _uniqueLocations([..._locations, created]);
        controller.text = created.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location "${created.name}" added.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to add location.')));
    }
  }

  List<LocationEntity> _uniqueLocations(List<LocationEntity> values) {
    final seen = <String>{};
    final out = <LocationEntity>[];
    for (final item in values) {
      final key = item.name.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      out.add(item);
    }
    return out;
  }
}

class _LookupAutocomplete<T extends Object> extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final List<T> options;
  final String Function(T item) display;
  final String Function(T item)? subtitle;
  final VoidCallback onChanged;
  final ValueChanged<T> onSelected;

  const _LookupAutocomplete({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.options,
    required this.display,
    required this.onChanged,
    required this.onSelected,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>(
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) {
          return options.take(40);
        }
        return options
            .where((item) => display(item).toLowerCase().contains(query))
            .take(30);
      },
      displayStringForOption: display,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        if (!focusNode.hasFocus && textController.text != controller.text) {
          textController.value = TextEditingValue(
            text: controller.text,
            selection: TextSelection.collapsed(offset: controller.text.length),
          );
        }
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: labelText, hintText: hintText),
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Required' : null,
          onChanged: (value) {
            if (controller.text != value) {
              controller.value = TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              );
            }
            onChanged();
          },
        );
      },
      onSelected: (item) {
        final selected = display(item);
        controller.value = TextEditingValue(
          text: selected,
          selection: TextSelection.collapsed(offset: selected.length),
        );
        onSelected(item);
      },
      optionsViewBuilder: (context, onSelectedOption, filtered) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 280),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: filtered
                    .map(
                      (item) => ListTile(
                        title: Text(display(item)),
                        subtitle: subtitle == null
                            ? null
                            : Text(subtitle!(item)),
                        onTap: () => onSelectedOption(item),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LocationAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final List<LocationEntity> options;
  final VoidCallback onChanged;
  final ValueChanged<LocationEntity> onSelected;

  const _LocationAutocomplete({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.options,
    required this.onChanged,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<LocationEntity>(
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return options.take(40);
        return options
            .where((item) => item.name.toLowerCase().contains(query))
            .take(40);
      },
      displayStringForOption: (item) => item.name,
      onSelected: (item) {
        final selected = item.name;
        controller.value = TextEditingValue(
          text: selected,
          selection: TextSelection.collapsed(offset: selected.length),
        );
        onSelected(item);
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmit) {
        if (!focusNode.hasFocus && textController.text != controller.text) {
          textController.value = TextEditingValue(
            text: controller.text,
            selection: TextSelection.collapsed(offset: controller.text.length),
          );
        }
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            prefixIcon: const Icon(Icons.place_outlined),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          onChanged: (_) {
            final value = textController.text;
            if (controller.text != value) {
              controller.value = TextEditingValue(
                text: value,
                selection: TextSelection.collapsed(offset: value.length),
              );
            }
            onChanged();
          },
        );
      },
    );
  }
}

class _LocationAddInline extends StatelessWidget {
  final String text;
  final bool exists;
  final VoidCallback onAdd;

  const _LocationAddInline({
    required this.text,
    required this.exists,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || exists) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_location_alt_outlined, size: 18),
        label: Text('Add "$trimmed" as new location'),
      ),
    );
  }
}
