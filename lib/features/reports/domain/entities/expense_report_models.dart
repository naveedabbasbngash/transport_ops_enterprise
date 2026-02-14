class ExpenseReportOption {
  final String id;
  final String label;

  const ExpenseReportOption({
    required this.id,
    required this.label,
  });
}

class ExpenseReportItem {
  final String id;
  final String expenseDate;
  final String type;
  final double amount;
  final String? driverName;
  final String? truckPlateNo;
  final String? vendorName;
  final String? tripId;
  final String? notes;

  const ExpenseReportItem({
    required this.id,
    required this.expenseDate,
    required this.type,
    required this.amount,
    this.driverName,
    this.truckPlateNo,
    this.vendorName,
    this.tripId,
    this.notes,
  });
}

class ExpenseReportTotals {
  final int count;
  final double totalAmount;
  final double fuel;
  final double toll;
  final double repair;
  final double parking;
  final double penalty;
  final double officeMisc;

  const ExpenseReportTotals({
    required this.count,
    required this.totalAmount,
    required this.fuel,
    required this.toll,
    required this.repair,
    required this.parking,
    required this.penalty,
    required this.officeMisc,
  });

  static const zero = ExpenseReportTotals(
    count: 0,
    totalAmount: 0,
    fuel: 0,
    toll: 0,
    repair: 0,
    parking: 0,
    penalty: 0,
    officeMisc: 0,
  );
}

class BusinessKpis {
  final int tripCount;
  final double revenue;
  final double vendorCost;
  final double otherCost;
  final double expectedProfit;
  final int expenseCount;
  final double totalExpense;
  final double paymentsReceived;
  final double invoiceTotal;
  final double invoicePaid;
  final double invoiceOutstanding;
  final double netProfitAfterExpenses;

  const BusinessKpis({
    required this.tripCount,
    required this.revenue,
    required this.vendorCost,
    required this.otherCost,
    required this.expectedProfit,
    required this.expenseCount,
    required this.totalExpense,
    required this.paymentsReceived,
    required this.invoiceTotal,
    required this.invoicePaid,
    required this.invoiceOutstanding,
    required this.netProfitAfterExpenses,
  });

  static const zero = BusinessKpis(
    tripCount: 0,
    revenue: 0,
    vendorCost: 0,
    otherCost: 0,
    expectedProfit: 0,
    expenseCount: 0,
    totalExpense: 0,
    paymentsReceived: 0,
    invoiceTotal: 0,
    invoicePaid: 0,
    invoiceOutstanding: 0,
    netProfitAfterExpenses: 0,
  );
}

class ReportGroupRow {
  final String? id;
  final String label;
  final int tripCount;
  final double amount;

  const ReportGroupRow({
    required this.id,
    required this.label,
    required this.tripCount,
    required this.amount,
  });
}

class StatusRow {
  final String status;
  final int total;

  const StatusRow({
    required this.status,
    required this.total,
  });
}

class DriverPerformanceSummary {
  final int tripCount;
  final double revenue;
  final double vendorCost;
  final double otherCost;
  final double expectedProfit;
  final double driverExpenseTotal;
  final double profitAfterDriverExpenses;
  final List<ExpenseReportOption> expenseByType;

  const DriverPerformanceSummary({
    required this.tripCount,
    required this.revenue,
    required this.vendorCost,
    required this.otherCost,
    required this.expectedProfit,
    required this.driverExpenseTotal,
    required this.profitAfterDriverExpenses,
    this.expenseByType = const <ExpenseReportOption>[],
  });

  static const zero = DriverPerformanceSummary(
    tripCount: 0,
    revenue: 0,
    vendorCost: 0,
    otherCost: 0,
    expectedProfit: 0,
    driverExpenseTotal: 0,
    profitAfterDriverExpenses: 0,
  );
}

class VendorStatementSummary {
  final int tripCount;
  final double grossPayable;
  final double paid;
  final double balance;
  final List<ReportGroupRow> items;

  const VendorStatementSummary({
    required this.tripCount,
    required this.grossPayable,
    required this.paid,
    required this.balance,
    this.items = const <ReportGroupRow>[],
  });

  static const zero = VendorStatementSummary(
    tripCount: 0,
    grossPayable: 0,
    paid: 0,
    balance: 0,
  );
}
