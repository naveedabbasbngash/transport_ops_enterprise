class ExpenseState {
  final bool isSubmitting;
  final String? error;
  final bool success;

  const ExpenseState({
    required this.isSubmitting,
    required this.success,
    this.error,
  });

  factory ExpenseState.initial() {
    return const ExpenseState(isSubmitting: false, success: false);
  }

  ExpenseState copyWith({
    bool? isSubmitting,
    bool? success,
    String? error,
  }) {
    return ExpenseState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      success: success ?? this.success,
      error: error,
    );
  }
}
