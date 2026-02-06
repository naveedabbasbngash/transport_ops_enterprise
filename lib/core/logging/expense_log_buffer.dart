import 'package:flutter/foundation.dart';

class ExpenseLogEntry {
  final DateTime timestamp;
  final String message;

  const ExpenseLogEntry({
    required this.timestamp,
    required this.message,
  });
}

class ExpenseLogBuffer {
  ExpenseLogBuffer._();

  static final ValueNotifier<List<ExpenseLogEntry>> logs =
      ValueNotifier<List<ExpenseLogEntry>>(<ExpenseLogEntry>[]);

  static void add(String message) {
    final next = List<ExpenseLogEntry>.from(logs.value)
      ..add(
        ExpenseLogEntry(
          timestamp: DateTime.now(),
          message: message,
        ),
      );
    if (next.length > 200) {
      next.removeRange(0, next.length - 200);
    }
    logs.value = next;
    debugPrint('[ExpenseLog] $message');
  }

  static void clear() {
    logs.value = <ExpenseLogEntry>[];
  }
}
