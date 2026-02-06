import '../domain/entities/expense_entity.dart';

class ExpenseListState {
  static const Object _unset = Object();

  final bool isLoading;
  final String? error;
  final List<ExpenseEntity> expenses;
  final String search;
  final String type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? truckId;
  final String? driverId;
  final String? driverName;
  final String? plateNo;

  const ExpenseListState({
    required this.isLoading,
    required this.expenses,
    required this.search,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.truckId,
    this.driverId,
    this.driverName,
    this.plateNo,
    this.error,
  });

  factory ExpenseListState.initial() {
    return const ExpenseListState(
      isLoading: false,
      expenses: [],
      search: '',
      type: 'all',
      startDate: null,
      endDate: null,
      truckId: null,
      driverId: null,
      driverName: null,
      plateNo: null,
    );
  }

  ExpenseListState copyWith({
    bool? isLoading,
    List<ExpenseEntity>? expenses,
    String? search,
    String? type,
    Object? startDate = _unset,
    Object? endDate = _unset,
    Object? truckId = _unset,
    Object? driverId = _unset,
    Object? driverName = _unset,
    Object? plateNo = _unset,
    Object? error = _unset,
  }) {
    return ExpenseListState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      search: search ?? this.search,
      type: type ?? this.type,
      startDate:
          startDate == _unset ? this.startDate : startDate as DateTime?,
      endDate: endDate == _unset ? this.endDate : endDate as DateTime?,
      truckId: truckId == _unset ? this.truckId : truckId as String?,
      driverId: driverId == _unset ? this.driverId : driverId as String?,
      driverName:
          driverName == _unset ? this.driverName : driverName as String?,
      plateNo: plateNo == _unset ? this.plateNo : plateNo as String?,
      error: error == _unset ? this.error : error as String?,
    );
  }
}
