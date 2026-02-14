import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../domain/entities/order_entity.dart';
import 'orders_view_model.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersViewModelProvider);
    final vm = ref.read(ordersViewModelProvider.notifier);
    final isReadOnly =
        ref.watch(authViewModelProvider).user?.isOwnerReadOnly ?? true;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.of(
                  context,
                ).pushNamed(AppRoutes.orderCreate);
                if (created == true && mounted) {
                  vm.loadOrders();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Order'),
            ),
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
                  const Text(
                    'Orders',
                    style: TextStyle(
                      fontSize: AppTypography.title,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: state.isLoading ? null : vm.loadOrders,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.page,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 380,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) {
                                    _debounce?.cancel();
                                    _debounce = Timer(
                                      const Duration(milliseconds: 350),
                                      () {
                                        if (!mounted) return;
                                        vm.onQueryChanged(value);
                                      },
                                    );
                                  },
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search_rounded),
                                    hintText:
                                        'Search by order no, client, notes',
                                  ),
                                ),
                              ),
                              ...[
                                'all',
                                'draft',
                                'confirmed',
                                'in_progress',
                                'completed',
                                'cancelled',
                              ].map(
                                (item) => ChoiceChip(
                                  label: Text(item.replaceAll('_', ' ')),
                                  selected: state.statusFilter == item,
                                  onSelected: (_) => vm.setStatusFilter(item),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (state.isLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              state.error!,
                              style: const TextStyle(
                                color: AppColors.dangerRed,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (state.orders.isEmpty)
                          _empty()
                        else
                          ...state.orders.map(
                            (order) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _OrderCard(
                                order: order,
                                isReadOnly: isReadOnly,
                                onDelete: () => _deleteOrder(order.id),
                              ),
                            ),
                          ),
                      ],
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

  Widget _empty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 34, color: Colors.black45),
          SizedBox(height: 8),
          Text('No orders found.'),
        ],
      ),
    );
  }

  Future<void> _deleteOrder(String orderId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete order?'),
        content: const Text(
          'This will delete the order only if no trips are linked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final success = await ref
        .read(ordersViewModelProvider.notifier)
        .deleteOrder(orderId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Order deleted.')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete order (likely linked trips).'),
        ),
      );
    }
  }
}

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  final bool isReadOnly;
  final VoidCallback onDelete;

  const _OrderCard({
    required this.order,
    required this.isReadOnly,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      symbol: '${order.currency} ',
      decimalDigits: 0,
    );
    final perTripProfit =
        order.revenueExpected - order.vendorCost - order.companyOtherCost;
    final totalEstimatedProfit = perTripProfit * order.tripsCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRoutes.orderDetail, arguments: order),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNo?.isNotEmpty == true
                          ? order.orderNo!
                          : 'Order ${order.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _status(order.status),
                  if (!isReadOnly)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.orderEdit, arguments: order),
                    ),
                  if (!isReadOnly)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(Icons.business_rounded, order.clientName ?? '-'),
                  _pill(
                    Icons.route_rounded,
                    '${order.fromLocation ?? '-'} -> ${order.toLocation ?? '-'}',
                  ),
                  _pill(
                    Icons.local_shipping_rounded,
                    '${order.tripsCount} trips',
                  ),
                  _pill(Icons.event_rounded, order.orderDate ?? '-'),
                  _pill(
                    Icons.trending_up_rounded,
                    'Estimated profit ${money.format(totalEstimatedProfit)}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(text),
        ],
      ),
    );
  }

  Widget _status(String status) {
    final normalized = status.toLowerCase();
    Color bg = AppColors.primaryBlueLight;
    Color fg = AppColors.primaryBlueText;
    if (normalized == 'completed') {
      bg = AppColors.successLight;
      fg = AppColors.successDark;
    } else if (normalized == 'cancelled') {
      bg = AppColors.dangerLight;
      fg = AppColors.dangerDark;
    } else if (normalized == 'in_progress') {
      bg = const Color(0xFFFFF7E0);
      fg = const Color(0xFF8A5A00);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
