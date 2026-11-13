part of 'stores_customers_bloc.dart';

abstract class StoresCustomersEvent {
  const StoresCustomersEvent();
}

class StoresCustomersLoadEvent extends StoresCustomersEvent {
  const StoresCustomersLoadEvent();
}
