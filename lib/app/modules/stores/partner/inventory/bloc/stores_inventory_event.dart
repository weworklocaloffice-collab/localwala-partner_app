part of 'stores_inventory_bloc.dart';

abstract class StoresInventoryEvent {
  const StoresInventoryEvent();
}

class StoresInventoryLoadEvent extends StoresInventoryEvent {
  const StoresInventoryLoadEvent({this.lowOnly = false});
  final bool lowOnly;
}
