import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../domain/entities/expense_entity.dart';
import 'expense_view_model.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final ExpenseEntity expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(expenseViewModelProvider.notifier);
    final authState = ref.watch(authViewModelProvider);
    final isReadOnly = authState.user?.isOwnerReadOnly ?? true;
    final amount = NumberFormat.currency(
      symbol: 'SAR ',
      decimalDigits: 0,
    ).format(expense.amount);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              isReadOnly: isReadOnly,
              onEdit: () => Navigator.of(
                context,
              ).pushNamed(AppRoutes.expenseEdit, arguments: expense),
              onDelete: () async {
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
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.page,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Hero(
                          expenseType: expense.type,
                          expenseDate: expense.expenseDate,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 700;
                            if (wide) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      label: 'Amount',
                                      value: amount,
                                      color: AppColors.primaryBlue,
                                      icon: Icons.payments_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      label: 'Type',
                                      value: expense.type.toUpperCase(),
                                      color: AppColors.successGreen,
                                      icon: Icons.receipt_long_rounded,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _MetricCard(
                                  label: 'Amount',
                                  value: amount,
                                  color: AppColors.primaryBlue,
                                  icon: Icons.payments_rounded,
                                ),
                                const SizedBox(height: 10),
                                _MetricCard(
                                  label: 'Type',
                                  value: expense.type.toUpperCase(),
                                  color: AppColors.successGreen,
                                  icon: Icons.receipt_long_rounded,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Panel(
                          title: 'Details',
                          children: [
                            _DetailRow(
                              label: 'Trip ID',
                              value: expense.tripId ?? '-',
                            ),
                            _DetailRow(
                              label: 'Truck ID',
                              value: expense.truckId ?? '-',
                            ),
                            _DetailRow(
                              label: 'Driver ID',
                              value: expense.driverId ?? '-',
                            ),
                            _DetailRow(
                              label: 'Vendor ID',
                              value: expense.vendorId ?? '-',
                            ),
                            _DetailRow(
                              label: 'Notes',
                              value: expense.notes ?? '-',
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Panel(
                          title: 'Audit',
                          children: [
                            _DetailRow(
                              label: 'Created',
                              value: expense.createdAt ?? '-',
                            ),
                            _DetailRow(
                              label: 'Updated',
                              value: expense.updatedAt ?? '-',
                            ),
                          ],
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
}

class _TopBar extends StatelessWidget {
  final bool isReadOnly;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TopBar({
    required this.isReadOnly,
    required this.onEdit,
    required this.onDelete,
  });

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
          const Text(
            'Expense Detail',
            style: TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (!isReadOnly)
            IconButton(icon: const Icon(Icons.edit_rounded), onPressed: onEdit),
          if (!isReadOnly)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String expenseType;
  final String expenseDate;

  const _Hero({required this.expenseType, required this.expenseDate});

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
            expenseType.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          _Pill(text: expenseDate),
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.panel,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Panel({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
