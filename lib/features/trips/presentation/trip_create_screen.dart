import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../shared/providers/api_client_provider.dart';
import '../../../shared/providers/provider_repository_provider.dart';
import '../../providers/domain/entities/provider_entity.dart';
import '../../../shared/providers/order_repository_provider.dart';
import '../../../shared/providers/driver_repository_provider.dart';
import '../../../shared/providers/location_repository_provider.dart';
import '../../../shared/providers/truck_repository_provider.dart';
import '../../drivers/domain/entities/driver_entity.dart';
import '../../orders/domain/entities/order_entity.dart';
import '../../trucks/domain/entities/truck_entity.dart';
import '../domain/entities/client_entity.dart';
import '../domain/entities/create_trip_input.dart';
import '../domain/entities/location_entity.dart';
import '../domain/entities/trip_entity.dart';
import '../domain/entities/vendor_entity.dart';
import 'trips_view_model.dart';

class TripCreateScreen extends ConsumerStatefulWidget {
  const TripCreateScreen({
    super.key,
    this.trip,
    this.seedTrip,
    this.initialOrderId,
  });

  final TripEntity? trip;
  final TripEntity? seedTrip;
  final String? initialOrderId;

  bool get isEdit => trip != null;
  bool get isDuplicate => trip == null && seedTrip != null;

  @override
  ConsumerState<TripCreateScreen> createState() => _TripCreateScreenState();
}

class _TripCreateScreenState extends ConsumerState<TripCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _dateController = TextEditingController();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _referenceController = TextEditingController();
  final _bookingController = TextEditingController();
  final _waybillController = TextEditingController();
  final _truckController = TextEditingController();
  final _truckTypeController = TextEditingController();
  final _driverController = TextEditingController();
  final _clientController = TextEditingController();
  final _vendorController = TextEditingController();
  final _revenueController = TextEditingController();
  final _vendorCostController = TextEditingController();
  final _companyOtherCostController = TextEditingController();
  final _remarksController = TextEditingController();

  bool _loadingLookups = true;
  List<ClientEntity> _clients = const [];
  List<DriverEntity> _drivers = const [];
  List<TruckEntity> _trucks = const [];
  List<VendorEntity> _vendors = const [];
  List<LocationEntity> _locations = const [];
  ClientEntity? _selectedClient;
  DriverEntity? _selectedDriver;
  TruckEntity? _selectedTruck;
  VendorEntity? _selectedVendor;
  OrderEntity? _linkedOrder;
  String _source = 'other';
  String _currency = 'SAR';
  String _lastDriverSelectionText = '';
  String _lastTruckSelectionText = '';

  bool get _isOrderLinked => _linkedOrder != null;
  bool _isBlankOrLiteralNull(String? value) {
    if (value == null) return true;
    final v = value.trim();
    if (v.isEmpty) return true;
    final lower = v.toLowerCase();
    return lower == 'null' || lower == 'n/a' || lower == 'none';
  }

  bool get _isDriverMissingPhone => _isBlankOrLiteralNull(
        _selectedDriver?.phone,
      );
  bool get _isDriverMissingIqama => _isBlankOrLiteralNull(
        _selectedDriver?.iqamaAttachment,
      );
  bool get _isTruckMissingDoc => _isBlankOrLiteralNull(
        _selectedTruck?.registrationCardUrl,
      );
  bool get _isTruckMissingOwner =>
      _isBlankOrLiteralNull(_selectedTruck?.ownerName);
  bool get _isTruckMissingCompany =>
      _isBlankOrLiteralNull(_selectedTruck?.companyName);

  @override
  void initState() {
    super.initState();
    _setInitialValues();
    _loadLookups();
  }

  void _setInitialValues() {
    final trip = widget.trip ?? widget.seedTrip;
    if (trip != null) {
      _dateController.text = trip.tripDate;
      _fromController.text = trip.fromLocation;
      _toController.text = trip.toLocation;
      _referenceController.text = trip.referenceNo ?? '';
      _bookingController.text = trip.bookingNo ?? '';
      _waybillController.text = trip.waybillNo;
      _truckController.text = trip.plateNo;
      _truckTypeController.text = trip.vehicleType;
      _driverController.text = trip.driverName;
      _clientController.text = trip.clientName;
      _revenueController.text = _toMoneyText(trip.tripAmount);
      _vendorCostController.text = _toMoneyText(trip.vendorCost);
      _companyOtherCostController.text = _toMoneyText(trip.companyOtherCost);
      _remarksController.text = trip.remarks;
      _source = trip.source ?? 'other';
      _currency = trip.currency ?? 'SAR';
      return;
    }

    final now = DateTime.now();
    _dateController.text =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    _revenueController.text = '0';
    _vendorCostController.text = '0';
    _companyOtherCostController.text = '0';
  }

  @override
  void dispose() {
    _dateController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _referenceController.dispose();
    _bookingController.dispose();
    _waybillController.dispose();
    _truckController.dispose();
    _truckTypeController.dispose();
    _driverController.dispose();
    _clientController.dispose();
    _vendorController.dispose();
    _revenueController.dispose();
    _vendorCostController.dispose();
    _companyOtherCostController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final driverRepo = ref.read(driverRepositoryProvider);
      final truckRepo = ref.read(truckRepositoryProvider);
      final locationRepo = ref.read(locationRepositoryProvider);
      final orderRepo = ref.read(orderRepositoryProvider);
      final linkedOrderId =
          (widget.trip ?? widget.seedTrip)?.orderId ?? widget.initialOrderId;
      final tripsVm = ref.read(tripsViewModelProvider.notifier);
      final results = await Future.wait<dynamic>([
        tripsVm.getClients(status: 'active'),
        driverRepo.getDrivers(status: 'active'),
        truckRepo.getTrucks(status: 'active'),
        tripsVm.getVendors(status: 'active'),
        locationRepo.getLocations(status: 'active', limit: 500),
        (linkedOrderId != null && linkedOrderId.isNotEmpty)
            ? orderRepo.getOrderById(linkedOrderId)
            : Future.value(null),
      ]);
      if (!mounted) return;
      setState(() {
        _clients = _uniqueClients(results[0] as List<ClientEntity>);
        _drivers = _uniqueDrivers(results[1] as List<DriverEntity>);
        _trucks = _uniqueTrucks(results[2] as List<TruckEntity>);
        _vendors = _uniqueVendors(results[3] as List<VendorEntity>);
        _locations = _uniqueLocations(results[4] as List<LocationEntity>);
        _linkedOrder = results[5] as OrderEntity?;
        _applyLinkedOrderDefaults();
        _resolveSelectionsFromInitialTrip();
        _loadingLookups = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLookups = false);
    }
  }

  Future<void> _openProviderDirectory() async {
    await Navigator.of(context).pushNamed(AppRoutes.providers);
    if (!mounted) return;
    await _loadLookups();
  }

  Future<void> _openProviderQuickAddSheet({String? initialName}) async {
    final nameController = TextEditingController(text: initialName ?? '');
    final phoneController = TextEditingController();
    final externalRefController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var status = 'active';
    var type = 'regular_vendor';
    var isSubmitting = false;

    VendorEntity? providerFromResult(dynamic obj) {
      if (obj is VendorEntity) return obj;
      if (obj is ProviderEntity) {
        return VendorEntity(
          id: obj.id,
          name: obj.name,
          status: obj.status,
          type: obj.type,
        );
      }
      return null;
    }

    final created = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              if (isSubmitting) return;
              if (!formKey.currentState!.validate()) return;
              final desiredName = nameController.text.trim();
              if (desiredName.isNotEmpty) {
                final existing = _vendors.firstWhere(
                  (item) =>
                      item.name.toLowerCase().trim() ==
                      desiredName.toLowerCase().trim(),
                  orElse: () => const VendorEntity(
                    id: '',
                    name: '',
                    status: '',
                    type: '',
                  ),
                );
                if (existing.id.isNotEmpty) {
                  if (!context.mounted) return;
                  Future.microtask(() {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop(existing);
                    }
                  });
                  return;
                }
              }

              setSheetState(() => isSubmitting = true);
              var didClose = false;
              final repo = ref.read(providerRepositoryProvider);
              try {
                final provider = await repo.createProvider(
                  name: desiredName,
                  type: type,
                  status: status,
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                  externalRef: externalRefController.text.trim().isEmpty
                      ? null
                      : externalRefController.text.trim(),
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
                if (!context.mounted) return;
                FocusScope.of(context).unfocus();
                final mapped = providerFromResult(provider) ?? _selectedVendor;
                Future.microtask(() {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(mapped);
                  }
                });
                didClose = true;
              } catch (err) {
                try {
                  await _loadLookups().timeout(const Duration(seconds: 8));
                } catch (_) {}
                if (!context.mounted) return;
                final fallback = _vendors.firstWhere(
                  (item) =>
                      item.name.toLowerCase().trim() ==
                      desiredName.toLowerCase().trim(),
                  orElse: () => const VendorEntity(
                    id: '',
                    name: '',
                    status: '',
                    type: '',
                  ),
                );
                if (fallback.id.isNotEmpty) {
                  FocusScope.of(context).unfocus();
                  Future.microtask(() {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop(fallback);
                    }
                  });
                  didClose = true;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unable to create provider: $err')),
                  );
                }
              } finally {
                if (!didClose && context.mounted) {
                  setSheetState(() => isSubmitting = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'New Provider',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'Provider name'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(
                            value: 'regular_vendor',
                            child: Text('Regular Vendor'),
                          ),
                          DropdownMenuItem(
                            value: 'spot_market_vendor',
                            child: Text('Spot Market Vendor'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => type = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => status = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: externalRefController,
                        decoration: const InputDecoration(
                          labelText: 'External Ref (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: 'Notes'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: isSubmitting ? null : submit,
                        child: isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Provider'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    final mappedCreated = providerFromResult(created);
    if (mappedCreated != null) {
      await _loadLookups();
      if (!mounted) return;
      setState(() {
        _selectedVendor = mappedCreated;
        _vendorController.text = mappedCreated.name;
      });
    }
  }

  Future<void> _openDriverQuickFixSheet() async {
    final driver = _selectedDriver;
    if (driver == null) return;
    final phoneController = TextEditingController(text: driver.phone ?? '');
    PlatformFile? iqamaFile;
    var isSaving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickIqama() async {
              final picked = await FilePicker.platform.pickFiles(
                allowMultiple: false,
                withData: true,
                type: FileType.custom,
                allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
              );
              if (picked == null || picked.files.isEmpty) return;
              setSheetState(() => iqamaFile = picked.files.first);
            }

            Future<void> save() async {
              final phone = phoneController.text.trim();
              final needsIqama = _isDriverMissingIqama;
              if (phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter driver mobile number.')),
                );
                return;
              }
              if (needsIqama && iqamaFile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attach driver iqama document.')),
                );
                return;
              }

              setSheetState(() => isSaving = true);
              final api = ref.read(apiClientProvider);
              final update = await api.putJson(
                'drivers/${driver.id}',
                body: {'phone': phone},
              );
              if (update['status'] != 'success') {
                setSheetState(() => isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not update driver.')),
                );
                return;
              }

              if (iqamaFile != null) {
                final bytes = iqamaFile!.bytes;
                if (bytes == null || bytes.isEmpty) {
                  setSheetState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid iqama file.')),
                  );
                  return;
                }
                final upload = await api.postMultipart(
                  'drivers/${driver.id}/iqama',
                  headers: const {'Accept': 'application/json'},
                  files: [
                    http.MultipartFile.fromBytes(
                      'iqama_attachment',
                      bytes,
                      filename: iqamaFile!.name,
                    ),
                  ],
                );
                if (upload.statusCode < 200 || upload.statusCode >= 300) {
                  setSheetState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Iqama upload failed (${upload.statusCode}).',
                      ),
                    ),
                  );
                  return;
                }
              }

              if (!context.mounted) return;
              Navigator.of(context).pop(true);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Update Driver',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    driver.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.badge_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            iqamaFile?.name ??
                                (driver.iqamaAttachment?.isNotEmpty == true
                                    ? 'Iqama document already uploaded'
                                    : 'No iqama document selected'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: isSaving ? null : pickIqama,
                          child: Text(
                            iqamaFile == null ? 'Attach' : 'Replace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : save,
                      icon: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text('Save Driver'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    phoneController.dispose();

    if (result == true) {
      await _loadLookups();
      if (!mounted) return;
      setState(() {
        _selectedDriver = _drivers.firstWhere(
          (item) => item.id == driver.id,
          orElse: () => _selectedDriver!,
        );
        _driverController.text = _selectedDriver?.name ?? _driverController.text;
      });
    }
  }

  Future<void> _openTruckQuickFixSheet() async {
    final truck = _selectedTruck;
    if (truck == null) return;
    final ownerController =
        TextEditingController(text: truck.ownerName ?? '');
    final companyController =
        TextEditingController(text: truck.companyName ?? '');
    final regNoController =
        TextEditingController(text: truck.registrationNumber ?? '');
    final modelController = TextEditingController(text: truck.model ?? '');
    final colorController = TextEditingController(text: truck.color ?? '');
    final yearController = TextEditingController(text: truck.makeYear ?? '');
    PlatformFile? regCardFile;
    var isSaving = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickRegCard() async {
              final picked = await FilePicker.platform.pickFiles(
                allowMultiple: false,
                withData: true,
                type: FileType.custom,
                allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
              );
              if (picked == null || picked.files.isEmpty) return;
              setSheetState(() => regCardFile = picked.files.first);
            }

            Future<void> save() async {
              final owner = ownerController.text.trim();
              final company = companyController.text.trim();

              if (owner.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter owner name.')),
                );
                return;
              }
              if (company.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter company name.')),
                );
                return;
              }
              if (_isTruckMissingDoc && regCardFile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Attach truck registration card.'),
                  ),
                );
                return;
              }

              setSheetState(() => isSaving = true);
              final api = ref.read(apiClientProvider);
              final update = await api.putJson(
                'trucks/${truck.id}',
                body: {
                  'owner_name': owner,
                  'company_name': company,
                  'registration_number': regNoController.text.trim(),
                  'model': modelController.text.trim(),
                  'color': colorController.text.trim(),
                  'make_year': yearController.text.trim(),
                },
              );
              if (update['status'] != 'success') {
                setSheetState(() => isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not update truck.')),
                );
                return;
              }

              if (regCardFile != null) {
                final bytes = regCardFile!.bytes;
                if (bytes == null || bytes.isEmpty) {
                  setSheetState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid document file.')),
                  );
                  return;
                }
                final upload = await api.postMultipart(
                  'trucks/${truck.id}/registration-card',
                  headers: const {'Accept': 'application/json'},
                  files: [
                    http.MultipartFile.fromBytes(
                      'registration_card',
                      bytes,
                      filename: regCardFile!.name,
                    ),
                  ],
                );
                if (upload.statusCode < 200 || upload.statusCode >= 300) {
                  setSheetState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Document upload failed (${upload.statusCode}).',
                      ),
                    ),
                  );
                  return;
                }
              }

              if (!context.mounted) return;
              Navigator.of(context).pop(true);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Update Truck',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    truck.plateNo,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: ownerController,
                    decoration: const InputDecoration(
                      labelText: 'Owner name',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company name',
                      prefixIcon: Icon(Icons.business_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: regNoController,
                    decoration: const InputDecoration(
                      labelText: 'Registration number',
                      prefixIcon: Icon(Icons.confirmation_number_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model',
                            prefixIcon: Icon(Icons.local_shipping_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: colorController,
                          decoration: const InputDecoration(
                            labelText: 'Color',
                            prefixIcon: Icon(Icons.palette_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: yearController,
                    decoration: const InputDecoration(
                      labelText: 'Make year',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            regCardFile?.name ??
                                (truck.registrationCardUrl?.isNotEmpty == true
                                    ? 'Registration card already uploaded'
                                    : 'No registration card selected'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: isSaving ? null : pickRegCard,
                          child: Text(
                            regCardFile == null ? 'Attach' : 'Replace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isSaving ? null : save,
                      icon: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text('Save Truck'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    ownerController.dispose();
    companyController.dispose();
    regNoController.dispose();
    modelController.dispose();
    colorController.dispose();
    yearController.dispose();

    if (result == true) {
      await _loadLookups();
      if (!mounted) return;
      setState(() {
        _selectedTruck = _trucks.firstWhere(
          (item) => item.id == truck.id,
          orElse: () => _selectedTruck!,
        );
        _truckController.text =
            _selectedTruck?.plateNo ?? _truckController.text;
        _truckTypeController.text =
            _selectedTruck?.truckType ?? _truckTypeController.text;
      });
    }
  }

  void _applyLinkedOrderDefaults() {
    final order = _linkedOrder;
    if (order == null) return;
    if ((order.clientId ?? '').isNotEmpty) {
      for (final item in _clients) {
        if (item.id == order.clientId) {
          _selectedClient = item;
          break;
        }
      }
    }
    _clientController.text = order.clientName ?? _clientController.text;
    _fromController.text = order.fromLocation ?? '';
    _toController.text = order.toLocation ?? '';
    if (!widget.isEdit && widget.seedTrip == null) {
      _revenueController.text = _toMoneyText(order.revenueExpected);
      _vendorCostController.text = _toMoneyText(order.vendorCost);
      _companyOtherCostController.text = _toMoneyText(order.companyOtherCost);
      _currency = order.currency.isEmpty ? 'SAR' : order.currency;
      if ((order.financialNotes ?? '').isNotEmpty) {
        _remarksController.text = order.financialNotes!;
      }
    }
  }

  void _resolveSelectionsFromInitialTrip() {
    final trip = widget.trip ?? widget.seedTrip;
    if (trip == null) return;

    _selectedClient = _clients.firstWhere(
      (item) => item.id == (trip.clientId ?? ''),
      orElse: () => _clients.firstWhere(
        (item) => item.name.toLowerCase() == trip.clientName.toLowerCase(),
        orElse: () => const ClientEntity(id: '', name: '', status: ''),
      ),
    );
    if (_selectedClient?.id == '') _selectedClient = null;

    _selectedDriver = _drivers.firstWhere(
      (item) => item.id == (trip.driverId ?? ''),
      orElse: () => _drivers.firstWhere(
        (item) => item.name.toLowerCase() == trip.driverName.toLowerCase(),
        orElse: () =>
            const DriverEntity(id: '', name: '', driverType: '', status: ''),
      ),
    );
    if (_selectedDriver?.id == '') _selectedDriver = null;

    _selectedTruck = _trucks.firstWhere(
      (item) => item.id == (trip.truckId ?? ''),
      orElse: () => _trucks.firstWhere(
        (item) => item.plateNo.toLowerCase() == trip.plateNo.toLowerCase(),
        orElse: () => const TruckEntity(id: '', plateNo: '', status: ''),
      ),
    );
    if (_selectedTruck?.id == '') _selectedTruck = null;

    _selectedVendor = _vendors.firstWhere(
      (item) => item.id == (trip.vendorId ?? ''),
      orElse: () => const VendorEntity(id: '', name: '', status: ''),
    );
    if (_selectedVendor?.id == '') _selectedVendor = null;

    if (_selectedClient != null) _clientController.text = _selectedClient!.name;
    if (_selectedDriver != null) _driverController.text = _selectedDriver!.name;
    if (_selectedTruck != null) {
      _truckController.text = _selectedTruck!.plateNo;
      _truckTypeController.text = _selectedTruck!.truckType ?? trip.vehicleType;
    }
    if (_selectedVendor != null) _vendorController.text = _selectedVendor!.name;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripsViewModelProvider);
    final inputTheme = Theme.of(context).inputDecorationTheme.copyWith(
      filled: true,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _CreateTopBar(
              title: widget.isEdit
                  ? 'Edit Trip'
                  : (widget.isDuplicate ? 'Duplicate Trip' : 'New Trip'),
            ),
            Expanded(
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(inputDecorationTheme: inputTheme),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 980;
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _CreateHero(
                            isEdit: widget.isEdit,
                            isDuplicate: widget.isDuplicate,
                            source: _source,
                            currency: _currency,
                          ),
                          if (_loadingLookups) ...[
                            const SizedBox(height: 10),
                            const LinearProgressIndicator(minHeight: 2),
                          ],
                          const SizedBox(height: 12),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _tripSection()),
                                const SizedBox(width: 16),
                                Expanded(child: _assignmentSection()),
                              ],
                            )
                          else ...[
                            _tripSection(),
                            const SizedBox(height: 16),
                            _assignmentSection(),
                          ],
                          const SizedBox(height: 16),
                          _referenceSection(),
                          const SizedBox(height: 16),
                          _financialSection(),
                          if (state.error != null) ...[
                            const SizedBox(height: 14),
                            _FormErrorBanner(message: state.error!),
                          ],
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accentOrange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: state.isSubmitting || _loadingLookups
                                ? null
                                : _submit,
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
                            label: Text(
                              widget.isEdit ? 'Update Trip' : 'Create Trip',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripSection() {
    return _FormPanel(
      title: 'Trip',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          TextFormField(
            controller: _dateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Trip date',
              prefixIcon: Icon(Icons.calendar_today_rounded),
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Required' : null,
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 2),
                initialDate: DateTime.tryParse(_dateController.text) ?? now,
              );
              if (picked == null) return;
              _dateController.text =
                  '${picked.year.toString().padLeft(4, '0')}-'
                  '${picked.month.toString().padLeft(2, '0')}-'
                  '${picked.day.toString().padLeft(2, '0')}';
            },
          ),
          const SizedBox(height: 12),
          _LookupAutocomplete<ClientEntity>(
            controller: _clientController,
            labelText: 'Client',
            hintText: 'Type client name',
            options: _clients,
            display: (item) => item.name,
            subtitle: (item) => item.status,
            onChanged: (_) => _selectedClient = null,
            onSelected: (item) {
              _selectedClient = item;
            },
          ),
          if (!_isOrderLinked) ...[
            const SizedBox(height: 12),
            _LookupAutocomplete<LocationEntity>(
              controller: _fromController,
              labelText: 'From location',
              hintText: 'Type or select location',
              options: _locations,
              display: (item) => item.name,
              subtitle: (item) => item.status,
              onChanged: (_) => setState(() {}),
              onSelected: (_) => setState(() {}),
            ),
            _LocationAddInline(
              text: _fromController.text,
              exists: _locationExists(_fromController.text),
              onAdd: () => _addLocationFromInput(_fromController, 'From'),
            ),
            const SizedBox(height: 12),
            _LookupAutocomplete<LocationEntity>(
              controller: _toController,
              labelText: 'To location',
              hintText: 'Type or select location',
              options: _locations,
              display: (item) => item.name,
              subtitle: (item) => item.status,
              onChanged: (_) => setState(() {}),
              onSelected: (_) => setState(() {}),
            ),
            _LocationAddInline(
              text: _toController.text,
              exists: _locationExists(_toController.text),
              onAdd: () => _addLocationFromInput(_toController, 'To'),
            ),
          ] else ...[
            const SizedBox(height: 12),
            _InheritedFromOrderCard(order: _linkedOrder!),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _source,
            decoration: const InputDecoration(
              labelText: 'Source',
              prefixIcon: Icon(Icons.source_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'dsv_email', child: Text('DSV Email')),
              DropdownMenuItem(
                value: 'whatsapp_spot',
                child: Text('WhatsApp Spot'),
              ),
              DropdownMenuItem(value: 'phone', child: Text('Phone')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _source = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _assignmentSection() {
    return _FormPanel(
      title: 'Assignment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          _LookupAutocomplete<TruckEntity>(
            controller: _truckController,
            labelText: 'Truck',
            hintText: 'Type plate number',
            options: _trucks,
            display: (item) => item.plateNo,
            subtitle: (item) => item.truckType ?? item.status,
            onChanged: (value) {
              final text = value.trim();
              if (text.isNotEmpty && text == _lastTruckSelectionText) {
                return;
              }
              if (_selectedTruck != null &&
                  text == _selectedTruck!.plateNo.trim()) {
                return;
              }
              setState(() {
                _selectedTruck = null;
                _truckTypeController.clear();
                _lastTruckSelectionText = '';
              });
            },
            onSelected: (item) {
              setState(() {
                _selectedTruck = item;
                _truckTypeController.text = item.truckType ?? '';
                _lastTruckSelectionText = item.plateNo.trim();
              });
            },
          ),
          if (_selectedTruck != null) ...[
            const SizedBox(height: 10),
            _MissingTruckInfoCard(
              missingOwner: _isTruckMissingOwner,
              missingCompany: _isTruckMissingCompany,
              missingDoc: _isTruckMissingDoc,
              onFixPressed: _openTruckQuickFixSheet,
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _truckTypeController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Truck type',
              prefixIcon: Icon(Icons.local_shipping_outlined),
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _LookupAutocomplete<DriverEntity>(
            controller: _driverController,
            labelText: 'Driver',
            hintText: 'Type driver name',
            options: _drivers,
            display: (item) => item.name,
            subtitle: (item) => item.residentId ?? item.driverType,
            onChanged: (value) {
              final text = value.trim();
              if (text.isNotEmpty && text == _lastDriverSelectionText) {
                return;
              }
              if (_selectedDriver != null &&
                  text == _selectedDriver!.name.trim()) {
                return;
              }
              setState(() {
                _selectedDriver = null;
                _lastDriverSelectionText = '';
              });
            },
            onSelected: (item) {
              setState(() {
                _selectedDriver = item;
                _lastDriverSelectionText = item.name.trim();
              });
            },
          ),
          if (_selectedDriver != null) ...[
            const SizedBox(height: 10),
            _MissingDriverInfoCard(
              missingPhone: _isDriverMissingPhone,
              missingIqama: _isDriverMissingIqama,
              onFixPressed: _openDriverQuickFixSheet,
            ),
          ],
          const SizedBox(height: 12),
          _LookupAutocomplete<VendorEntity>(
            controller: _vendorController,
            labelText: 'Provider',
            hintText: 'Type provider name',
            options: _vendors,
            display: (item) => item.name,
            subtitle: (item) => item.type ?? item.status,
            onChanged: (_) => setState(() => _selectedVendor = null),
            onSelected: (item) {
              setState(() => _selectedVendor = item);
            },
            onAddNew: (query) {
              FocusScope.of(context).unfocus();
              _openProviderQuickAddSheet(initialName: query);
            },
          ),
          _ProviderAddInline(
            text: _vendorController.text,
            exists: _vendors.any(
              (item) =>
                  item.name.toLowerCase().trim() ==
                  _vendorController.text.toLowerCase().trim(),
            ),
            onAdd: () {
              FocusScope.of(context).unfocus();
              _openProviderQuickAddSheet(
                initialName: _vendorController.text.trim(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _referenceSection() {
    return _FormPanel(
      title: 'References',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          TextFormField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: 'Reference no (optional)',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bookingController,
            decoration: const InputDecoration(
              labelText: 'Booking no (optional)',
              prefixIcon: Icon(Icons.book_online_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _waybillController,
            decoration: const InputDecoration(
              labelText: 'Waybill no (optional)',
              prefixIcon: Icon(Icons.receipt_long_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialSection() {
    return _FormPanel(
      title: 'Financials',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          TextFormField(
            controller: _revenueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Revenue expected',
              prefixIcon: Icon(Icons.trending_up_rounded),
            ),
            validator: (value) => _validateAmount(value, allowZero: true),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _vendorCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Vendor cost',
              prefixIcon: Icon(Icons.storefront_rounded),
            ),
            validator: (value) => _validateAmount(value, allowZero: true),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _companyOtherCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Company other cost',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
            ),
            validator: (value) => _validateAmount(value, allowZero: true),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: const InputDecoration(
              labelText: 'Currency',
              prefixIcon: Icon(Icons.currency_exchange_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'SAR', child: Text('SAR')),
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'AED', child: Text('AED')),
            ],
            onChanged: (value) {
              if (value == null || value.isEmpty) return;
              setState(() => _currency = value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _remarksController,
            decoration: const InputDecoration(
              labelText: 'Remarks (optional)',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isOrderLinked && _selectedClient == null) {
      _showSelectionError('Select a client from suggestions.');
      return;
    }
    if (_selectedTruck == null) {
      _showSelectionError('Select a truck from suggestions.');
      return;
    }
    if (_isTruckMissingOwner || _isTruckMissingCompany || _isTruckMissingDoc) {
      _showSelectionError(
        'Truck is missing owner/company or registration card. Update the truck first.',
      );
      return;
    }
    if (_selectedDriver == null) {
      _showSelectionError('Select a driver from suggestions.');
      return;
    }
    if (_isDriverMissingPhone || _isDriverMissingIqama) {
      _showSelectionError(
        'Driver is missing mobile or iqama attachment. Update the driver first.',
      );
      return;
    }
    if (_selectedVendor == null) {
      _showSelectionError('Select a provider from suggestions.');
      return;
    }

    final effectiveClientId = _isOrderLinked
        ? (_linkedOrder?.clientId ?? _selectedClient?.id ?? '')
        : (_selectedClient?.id ?? '');
    if (effectiveClientId.isEmpty) {
      _showSelectionError('Order client is missing. Update order first.');
      return;
    }

    final payload = CreateTripInput(
      clientId: effectiveClientId,
      orderId: widget.isEdit
          ? widget.trip?.orderId
          : (widget.seedTrip?.orderId ?? widget.initialOrderId),
      tripDate: _dateController.text.trim(),
      fromLocation: _isOrderLinked
          ? (_linkedOrder?.fromLocation ?? '')
          : _fromController.text.trim(),
      toLocation: _isOrderLinked
          ? (_linkedOrder?.toLocation ?? '')
          : _toController.text.trim(),
      plateNo: _selectedTruck!.plateNo.trim(),
      truckType: _truckTypeController.text.trim(),
      referenceNo: _referenceController.text.trim(),
      bookingNo: _bookingController.text.trim(),
      waybillNo: _waybillController.text.trim(),
      truckId: _selectedTruck!.id,
      driverId: _selectedDriver!.id,
      driverName: _selectedDriver!.name.trim(),
      vendorId: _selectedVendor!.id,
      source: _source,
      revenueExpected: _toDouble(_revenueController.text),
      vendorCost: _toDouble(_vendorCostController.text),
      companyOtherCost: _toDouble(_companyOtherCostController.text),
      currency: _currency,
      remarks: _remarksController.text.trim(),
    );

    final vm = ref.read(tripsViewModelProvider.notifier);
    final success = widget.isEdit
        ? await vm.updateTrip(id: widget.trip!.id, input: payload)
        : await vm.createTrip(payload);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'Trip updated successfully.'
                : 'Trip created successfully.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
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
      _showSelectionError('Enter $label location first.');
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
      _showSelectionError('Unable to add location.');
    }
  }

  void _showSelectionError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LookupAutocomplete<T extends Object> extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final List<T> options;
  final String Function(T item) display;
  final String Function(T item)? subtitle;
  final ValueChanged<String> onChanged;
  final ValueChanged<T> onSelected;
  final ValueChanged<String>? onAddNew;

  const _LookupAutocomplete({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.options,
    required this.display,
    required this.onChanged,
    required this.onSelected,
    this.subtitle,
    this.onAddNew,
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
            onChanged(value);
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
        final query = controller.text.trim();
        final showAdd = onAddNew != null &&
            query.isNotEmpty &&
            !options.any(
              (item) => display(item).toLowerCase() == query.toLowerCase(),
            );
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
                children: [
                  ...filtered.map(
                    (item) => ListTile(
                      title: Text(display(item)),
                      subtitle:
                          subtitle == null ? null : Text(subtitle!(item)),
                      onTap: () => onSelectedOption(item),
                    ),
                  ),
                  if (showAdd)
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline_rounded),
                      title: Text('Add "$query"'),
                      onTap: () => onAddNew?.call(query),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MissingDriverInfoCard extends StatelessWidget {
  final bool missingPhone;
  final bool missingIqama;
  final VoidCallback onFixPressed;

  const _MissingDriverInfoCard({
    required this.missingPhone,
    required this.missingIqama,
    required this.onFixPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!missingPhone && !missingIqama) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningYellow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningYellow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver data missing',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (missingPhone)
                const _MissingPill(
                  icon: Icons.phone_rounded,
                  label: 'Add mobile no',
                ),
              if (missingIqama)
                const _MissingPill(
                  icon: Icons.badge_outlined,
                  label: 'Attach iqama',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onFixPressed,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Update driver'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MissingPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.warningYellow),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MissingTruckInfoCard extends StatelessWidget {
  final bool missingOwner;
  final bool missingCompany;
  final bool missingDoc;
  final VoidCallback onFixPressed;

  const _MissingTruckInfoCard({
    required this.missingOwner,
    required this.missingCompany,
    required this.missingDoc,
    required this.onFixPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!missingOwner && !missingCompany && !missingDoc) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningYellow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningYellow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Truck data missing',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (missingOwner)
                const _MissingPill(
                  icon: Icons.person_rounded,
                  label: 'Add owner name',
                ),
              if (missingCompany)
                const _MissingPill(
                  icon: Icons.business_rounded,
                  label: 'Add company name',
                ),
              if (missingDoc)
                const _MissingPill(
                  icon: Icons.description_outlined,
                  label: 'Attach registration card',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onFixPressed,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Update truck'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderAddInline extends StatelessWidget {
  final String text;
  final bool exists;
  final VoidCallback onAdd;

  const _ProviderAddInline({
    required this.text,
    required this.exists,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || exists) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: Text('Add "$trimmed"'),
        ),
      ),
    );
  }
}

class _InheritedFromOrderCard extends StatelessWidget {
  final OrderEntity order;

  const _InheritedFromOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inherited From Order',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('Client: ${order.clientName ?? '-'}'),
          Text('From: ${order.fromLocation ?? '-'}'),
          Text('To: ${order.toLocation ?? '-'}'),
        ],
      ),
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
    final value = text.trim();
    if (value.isEmpty || exists) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_circle_outline, size: 18),
        label: Text('Add "$value" as new location'),
      ),
    );
  }
}

List<ClientEntity> _uniqueClients(List<ClientEntity> values) {
  final seen = <String>{};
  final result = <ClientEntity>[];
  for (final item in values) {
    if (item.id.isEmpty || !seen.add(item.id)) continue;
    result.add(item);
  }
  return result;
}

List<DriverEntity> _uniqueDrivers(List<DriverEntity> values) {
  final seen = <String>{};
  final result = <DriverEntity>[];
  for (final item in values) {
    if (item.id.isEmpty || !seen.add(item.id)) continue;
    result.add(item);
  }
  return result;
}

List<TruckEntity> _uniqueTrucks(List<TruckEntity> values) {
  final seen = <String>{};
  final result = <TruckEntity>[];
  for (final item in values) {
    if (item.id.isEmpty || !seen.add(item.id)) continue;
    result.add(item);
  }
  return result;
}

List<VendorEntity> _uniqueVendors(List<VendorEntity> values) {
  final seen = <String>{};
  final result = <VendorEntity>[];
  for (final item in values) {
    if (item.id.isEmpty || !seen.add(item.id)) continue;
    result.add(item);
  }
  return result;
}

List<LocationEntity> _uniqueLocations(List<LocationEntity> values) {
  final seen = <String>{};
  final result = <LocationEntity>[];
  for (final item in values) {
    final key = item.name.trim().toLowerCase();
    if (key.isEmpty || !seen.add(key)) continue;
    result.add(item);
  }
  return result;
}

String _toMoneyText(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

String? _validateAmount(String? value, {required bool allowZero}) {
  final raw = (value ?? '').trim();
  final parsed = double.tryParse(raw);
  if (parsed == null) return 'Enter a valid number';
  if (!allowZero && parsed <= 0) return 'Must be greater than 0';
  if (allowZero && parsed < 0) return 'Cannot be negative';
  return null;
}

double _toDouble(String raw) {
  return double.tryParse(raw.trim()) ?? 0;
}

class _CreateTopBar extends StatelessWidget {
  final String title;

  const _CreateTopBar({required this.title});

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

class _CreateHero extends StatelessWidget {
  final bool isEdit;
  final bool isDuplicate;
  final String source;
  final String currency;

  const _CreateHero({
    required this.isEdit,
    required this.isDuplicate,
    required this.source,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            isEdit
                ? 'Update Existing Trip'
                : (isDuplicate ? 'Duplicate Trip' : 'Create New Trip'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          _HeroPill(text: source),
          _HeroPill(text: currency),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String text;

  const _HeroPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FormErrorBanner extends StatelessWidget {
  final String message;

  const _FormErrorBanner({required this.message});

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
