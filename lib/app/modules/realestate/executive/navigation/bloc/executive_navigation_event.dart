part of 'executive_navigation_bloc.dart';

abstract class ExecutiveNavigationEvent {
  const ExecutiveNavigationEvent();
}

class ExecutiveNavigationLoad extends ExecutiveNavigationEvent {
  const ExecutiveNavigationLoad(this.propertyId);
  final String propertyId;
}

class ExecutiveNavigationRefreshed extends ExecutiveNavigationEvent {
  const ExecutiveNavigationRefreshed(this.propertyId);
  final String propertyId;
}
