part of 'stores_orders_bloc.dart';

abstract class StoresOrdersEvent {
  const StoresOrdersEvent();
}

class StoresOrdersLoadEvent extends StoresOrdersEvent {
  const StoresOrdersLoadEvent({this.lifecycle});
  final String? lifecycle;
}
