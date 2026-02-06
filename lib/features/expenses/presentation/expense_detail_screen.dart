import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_routes.dart';
import '../domain/entities/expense_entity.dart';
import '../presentation/expense_view_model.dart';
import '../../auth/presentation/auth_view_model.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final ExpenseEntity expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewModel = ref.read(expenseViewModelProvider.notifier);
    final authState = ref.watch(authViewModelProvider);
    final isReadOnly = authState.user?.isOwnerReadOnly ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Detail'),
        actions: isReadOnly
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.expenseEdit,
                    arguments: expense,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete expense?'),
                        content: const Text(
                          'This will remove the expense record. Continue?',
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
                    if (confirmed != true) return;
                    await viewModel.deleteExpense(expense.id);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                ),
              ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailTile(
            label: 'Type',
            value: expense.type,
            icon: Icons.receipt_long_rounded,
          ),
          _DetailTile(
            label: 'Amount',
            value: expense.amount.toStringAsFixed(2),
            icon: Icons.payments_rounded,
          ),
          _DetailTile(
            label: 'Date',
            value: expense.expenseDate,
            icon: Icons.event_rounded,
          ),
          _DetailTile(
            label: 'Trip ID',
            value: expense.tripId ?? '-',
            icon: Icons.route_rounded,
          ),
          _DetailTile(
            label: 'Truck ID',
            value: expense.truckId ?? '-',
            icon: Icons.local_shipping_rounded,
          ),
          _DetailTile(
            label: 'Driver ID',
            value: expense.driverId ?? '-',
            icon: Icons.person_outline_rounded,
          ),
          _DetailTile(
            label: 'Notes',
            value: expense.notes ?? '-',
            icon: Icons.notes_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            'Audit',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _DetailTile(
            label: 'Created',
            value: expense.createdAt ?? '-',
            icon: Icons.schedule_rounded,
          ),
          _DetailTile(
            label: 'Updated',
            value: expense.updatedAt ?? '-',
            icon: Icons.update_rounded,
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
