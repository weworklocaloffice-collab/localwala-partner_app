part of 'executive_navigation_bloc.dart';

enum ExecutiveNavigationStatus { initial, loading, loaded, failure }

class ExecutiveNavigationState {
  const ExecutiveNavigationState({
    this.status = ExecutiveNavigationStatus.initial,
    this.property,
    this.message = '',
  });

  final ExecutiveNavigationStatus status;
  final RealEstatePropertyModel? property;
  final String message;

  ExecutiveNavigationState copyWith({
    ExecutiveNavigationStatus? status,
    RealEstatePropertyModel? property,
    String? message,
  }) {
    return ExecutiveNavigationState(
      status: status ?? this.status,
      property: property ?? this.property,
      message: message ?? this.message,
    );
  }
}
