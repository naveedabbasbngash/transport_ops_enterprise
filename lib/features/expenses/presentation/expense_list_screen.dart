import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../domain/entities/expense_entity.dart';
import 'expense_list_view_model.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseListViewModelProvider);
    final viewModel = ref.read(expenseListViewModelProvider.notifier);
    final authState = ref.watch(authViewModelProvider);
    final isReadOnly = authState.user?.isOwnerReadOnly ?? true;

    final filtered = _applySearch(viewModel.filtered, state.search);
    final totalAmount = filtered.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final fuelCount = filtered.where((e) => e.type == 'fuel').length;
    final repairCount = filtered.where((e) => e.type == 'repair').length;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              onPressed: () async {
                await Navigator.of(context).pushNamed(AppRoutes.expenseCreate);
                if (mounted) {
                  viewModel.loadExpenses();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Expense'),
            ),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: 'Expenses',
              isLoading: state.isLoading,
              onRefresh: () => viewModel.loadExpenses(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.page,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Hero(
                          subtitle: isReadOnly
                              ? 'Read only access'
                              : 'Edit enabled',
                          tag: '${filtered.length} filtered expenses',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Filters(
                          searchController: _searchController,
                          selectedType: state.type,
                          onSearchChanged: viewModel.updateSearch,
                          onTypeChanged: (value) {
                            viewModel.updateType(value);
                          },
                          onApply: viewModel.applyFilters,
                          onClear: () {
                            _searchController.clear();
                            viewModel.clearFilters();
                            viewModel.loadExpenses();
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 760;
                            if (wide) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: _MetricCard(
                                      label: 'Total Amount',
                                      value: _money(totalAmount),
                                      color: AppColors.primaryBlue,
                                      icon: Icons.payments_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      label: 'Fuel',
                                      value: '$fuelCount',
                                      color: AppColors.successGreen,
                                      icon: Icons.local_gas_station_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MetricCard(
                                      label: 'Repair',
                                      value: '$repairCount',
                                      color: AppColors.dangerRed,
                                      icon: Icons.build_rounded,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _MetricCard(
                                  label: 'Total Amount',
                                  value: _money(totalAmount),
                                  color: AppColors.primaryBlue,
                                  icon: Icons.payments_rounded,
                                ),
                                const SizedBox(height: 10),
                                _MetricCard(
                                  label: 'Fuel',
                                  value: '$fuelCount',
                                  color: AppColors.successGreen,
                                  icon: Icons.local_gas_station_rounded,
                                ),
                                const SizedBox(height: 10),
                                _MetricCard(
                                  label: 'Repair',
                                  value: '$repairCount',
                                  color: AppColors.dangerRed,
                                  icon: Icons.build_rounded,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (state.error != null)
                          _ErrorBanner(message: state.error!),
                        if (state.isLoading) ...[
                          const SizedBox(height: 10),
                          const LinearProgressIndicator(minHeight: 2),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _ListPanel(expenses: filtered, isReadOnly: isReadOnly),
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

  List<ExpenseEntity> _applySearch(List<ExpenseEntity> input, String search) {
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return input;
    return input.where((item) {
      return item.type.toLowerCase().contains(query) ||
          item.expenseDate.toLowerCase().contains(query) ||
          (item.notes ?? '').toLowerCase().contains(query) ||
          (item.tripId ?? '').toLowerCase().contains(query);
    }).toList();
  }

  String _money(double value) {
    return NumberFormat.currency(
      symbol: 'SAR ',
      decimalDigits: 0,
    ).format(value);
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _TopBar({
    required this.title,
    required this.isLoading,
    required this.onRefresh,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isLoading ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final String subtitle;
  final String tag;

  const _Hero({required this.subtitle, required this.tag});

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
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Expense Monitor',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          _Pill(text: subtitle),
          _Pill(text: tag),
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

class _Filters extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedType;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _Filters({
    required this.searchController,
    required this.selectedType,
    required this.onSearchChanged,
    required this.onTypeChanged,
    required this.onApply,
    required this.onClear,
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
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 420,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                labelText: 'Search expense',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'fuel', child: Text('Fuel')),
                DropdownMenuItem(value: 'repair', child: Text('Repair')),
                DropdownMenuItem(value: 'toll', child: Text('Toll')),
                DropdownMenuItem(value: 'penalty', child: Text('Penalty')),
                DropdownMenuItem(value: 'parking', child: Text('Parking')),
                DropdownMenuItem(
                  value: 'office_misc',
                  child: Text('Office Misc'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                onTypeChanged(value);
              },
            ),
          ),
          FilledButton(
            onPressed: onApply,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
          OutlinedButton(onPressed: onClear, child: const Text('Clear')),
        ],
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
                  fontSize: 20,
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

class _ListPanel extends StatelessWidget {
  final List<ExpenseEntity> expenses;
  final bool isReadOnly;

  const _ListPanel({required this.expenses, required this.isReadOnly});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: const Text(
          'No expenses found.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Column(
      children: expenses.map((expense) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ExpenseCard(expense: expense, isReadOnly: isReadOnly),
        );
      }).toList(),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseEntity expense;
  final bool isReadOnly;

  const _ExpenseCard({required this.expense, required this.isReadOnly});

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(
      symbol: 'SAR ',
      decimalDigits: 0,
    ).format(expense.amount);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRoutes.expenseDetail, arguments: expense),
        child: Ink(
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
                  color: AppColors.primaryBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.type.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${expense.expenseDate}${expense.notes?.isNotEmpty == true ? ' • ${expense.notes}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (!isReadOnly) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ],
          ),
        ),
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
