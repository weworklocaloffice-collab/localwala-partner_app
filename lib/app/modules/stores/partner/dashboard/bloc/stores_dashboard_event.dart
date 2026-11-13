part of 'stores_dashboard_bloc.dart';

abstract class StoresDashboardEvent {
  const StoresDashboardEvent();
}

class StoresDashboardLoadEvent extends StoresDashboardEvent {
  const StoresDashboardLoadEvent();
}
